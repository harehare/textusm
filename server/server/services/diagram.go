package services

import (
	"errors"
	"os"

	"github.com/harehare/textusm/server/models"
	"github.com/jinzhu/gorm"
)

var DB *gorm.DB

const FreePlanMaxDiagrams = 30

var EncryptKey = []byte(os.Getenv("ENCRYPT_KEY"))

type Page struct {
	Offset int
	Limit  int
}

func NewPage(pageNo int) Page {
	return Page{Offset: 10 * (pageNo - 1), Limit: 10 * pageNo}
}

func itemsToDto(items *[]models.Item) (*[]models.ItemDto, error) {
	dto := []models.ItemDto{}

	for _, item := range *items {
		i, err := models.ItemToDto(item)

		if err != nil {
			return nil, err
		}

		dto = append(dto, *i)
	}
	return &dto, nil
}

func getDiagramByID(id string) (*models.Item, error) {
	var diagram models.Item
	if err := DB.Model(&diagram).Where("id = ?", id).Find(&diagram).Error; err != nil {
		return nil, err
	}

	return &diagram, nil
}

func isDiagramOwner(userID, diagramID string) bool {

	diagram, err := getDiagramByID(diagramID)

	if err != nil {
		return false
	}

	return diagram.OwnerID == userID
}

func isDiagramOwnerFromItem(userID string, diagram *models.Item) bool {
	return diagram.OwnerID == userID
}

func isDiagramEditor(userID string, diagram *models.Item) bool {

	dto, err := models.ItemToDto(*diagram)

	if err != nil {
		return false
	}

	for _, u := range dto.Users {
		if u.ID == userID && u.Role == models.RoleEditor {
			return true
		}
	}

	return false
}

func Search(uid, query string, page Page) (*[]models.ItemDto, error) {
	var items []models.Item
	if err := DB.Select("id, owner_id, title, thumbnail, diagram_path, updated_at").Where("text LIKE ?", "%"+query).Where("LIKE ?", "%"+query).Where("owner_id = ?", uid).Or("users @> ?", "[{\"id\": \""+uid+"\"}]").Limit(page.Limit).Offset(page.Offset).Find(&items).Error; err != nil {
		return nil, err
	}

	i, err := itemsToDto(&items)

	if err != nil {
		return nil, err
	}

	return i, nil
}

func GetItems(uid string, page Page) (*[]models.ItemDto, error) {
	var items []models.Item
	if err := DB.Select("id, owner_id, title, thumbnail, diagram_path, updated_at").Where("owner_id = ?", uid).Or("users @> ?", "[{\"id\": \""+uid+"\"}]").Order("updated_at desc").Limit(page.Limit).Offset(page.Offset).Find(&items).Error; err != nil {
		return nil, err
	}

	i, err := itemsToDto(&items)

	if err != nil {
		return nil, err
	}

	return i, nil
}

func GetItem(uid string, diagramID string) (*models.ItemDto, error) {
	var item models.Item
	if err := DB.Where("id = ? AND (owner_id = ? OR users @> ?)", diagramID, uid, "[{\"id\": \""+uid+"\"}]").First(&item).Error; err != nil {
		return nil, err
	}

	text, err := decrypt(EncryptKey, item.Text)

	if err != nil {
		return nil, err
	}

	item.Text = text
	dto, err := models.ItemToDto(item)

	if err != nil {
		return nil, err
	}

	return dto, nil
}

func Remove(uid string, diagramID string) error {
	if !isDiagramOwner(uid, diagramID) {
		return errors.New("\"" + uid + "\" is not diagram owner.")
	}

	var item models.Item
	if err := DB.Where("id = ?", diagramID).Delete(&item).Error; err != nil {
		return err
	}
	return nil
}

func GetPublicItems(page Page) (*[]models.ItemDto, error) {
	var items []models.Item
	if err := DB.Select("id, owner_id, title, thumbnail, diagram_path, updated_at").Where("is_public = ?", true).Limit(page.Limit).Offset(page.Offset).Find(&items).Error; err != nil {
		return nil, err
	}

	i, err := itemsToDto(&items)

	if err != nil {
		return nil, err
	}

	return i, nil
}

func Save(uid string, item *models.Item) error {

	if !DB.NewRecord(&item) {
		currentItem, err := getDiagramByID(item.ID.String())

		if err != nil {
			return err
		}

		if !isDiagramOwnerFromItem(uid, currentItem) && !isDiagramEditor(uid, currentItem) {
			return errors.New("\"" + uid + "\" is not editable diagram.")
		}
	}

	var count int
	if err := DB.Model(models.Item{}).Select("id").Where("owner_id = ?", item.OwnerID).Count(&count).Error; err != nil {
		return err
	}

	if count > FreePlanMaxDiagrams {
		return errors.New("Cannot create anymore diagrams in free account")
	}

	encryptText, err := encrypt(EncryptKey, item.Text)

	if err != nil {
		return err
	}

	item.Text = encryptText

	if DB.NewRecord(&item) {
		item.OwnerID = uid
		if err := DB.Create(&item).Error; err != nil {
			return err
		}
	} else {
		if err := DB.Model(&item).Updates(&item).Error; err != nil {
			return err
		}
	}

	return nil
}

func UpdateRole(ownerID, updateUserUID, diagramID, role string) error {
	var diagram models.Item
	if err := DB.Model(&diagram).Where("id = ?", diagramID).Find(&diagram).Error; err != nil {
		return err
	}

	if !isDiagramOwnerFromItem(ownerID, &diagram) {
		return errors.New("\"" + ownerID + "\" is not diagram owner.")
	}

	u, err := models.JsonbToUsers(&diagram.Users)

	if err != nil {
		return err
	}

	users := []models.User{}

	for _, user := range *u {
		if user.ID == updateUserUID {
			user.Role = role
		}

		users = append(users, user)
	}

	jsonb, err := models.ToJSONB(&users)

	if err != nil {
		return err
	}

	diagram.Users = *jsonb

	if err := DB.Model(&diagram).Updates(&diagram).Error; err != nil {
		return err
	}

	return nil
}

func DeleteUser(ownerID, deleteUserUID, diagramID string) error {
	var diagram models.Item
	if err := DB.Model(&diagram).Where("id = ?", diagramID).Find(&diagram).Error; err != nil {
		return err
	}

	if !isDiagramOwnerFromItem(ownerID, &diagram) {
		return errors.New("\"" + ownerID + "\" is not diagram owner.")
	}

	u, err := models.JsonbToUsers(&diagram.Users)

	if err != nil {
		return err
	}

	users := []models.User{}

	for _, user := range *u {
		if user.ID != deleteUserUID {
			users = append(users, user)
		}
	}

	jsonb, err := models.ToJSONB(&users)

	if err != nil {
		return err
	}

	diagram.Users = *jsonb

	if err := DB.Model(&diagram).Updates(&diagram).Error; err != nil {
		return err
	}

	return nil
}

func AddUserToDiagram(ownerID string, addUserUID string, diagramID string) error {
	var diagram models.Item
	if err := DB.Model(&diagram).Where("id = ?", diagramID).Find(&diagram).Error; err != nil {
		return err
	}

	if !isDiagramOwnerFromItem(ownerID, &diagram) {
		return errors.New("\"" + ownerID + "\" is not diagram owner.")
	}

	u, err := models.JsonbToUsers(&diagram.Users)

	if err != nil {
		return err
	}

	users := *u
	users = append(users, models.User{ID: addUserUID, Role: models.RoleViewer})

	jsonb, err := models.ToJSONB(&users)

	if err != nil {
		return err
	}

	diagram.Users = *jsonb

	if err := DB.Model(&diagram).Updates(&diagram).Error; err != nil {
		return err
	}

	return nil
}
