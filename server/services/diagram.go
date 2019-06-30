package services

import (
	"errors"
	"os"

	"github.com/harehare/textusm/models"
	"github.com/jinzhu/gorm"
)

var DB *gorm.DB

const FreePlanMaxDiagrams = 10

var EncryptKey = []byte(os.Getenv("ENCRYPT_KEY"))

type Page struct {
	Offset int
	Limit  int
}

func NewPage(pageNo int) Page {
	return Page{Offset: 10 * (pageNo - 1), Limit: 10 * pageNo}
}

func itemsToDto(items *[]models.Item) *[]models.ItemDto {
	dto := []models.ItemDto{}

	for _, item := range *items {
		dto = append(dto, models.ItemToDto(item))
	}
	return &dto
}

func Search(query string, page Page) (*[]models.ItemDto, error) {
	var items []models.Item
	if err := DB.Select("id, owner_id, title, thumbnail, diagram_path, updated_at").Where("text LIKE ?", "%"+query).Where("LIKE ?", "%"+query).Limit(page.Limit).Offset(page.Offset).Find(&items).Error; err != nil {
		return nil, err
	}
	return itemsToDto(&items), nil
}

func GetItems(uid string, page Page) (*[]models.ItemDto, error) {
	var items []models.Item
	if err := DB.Select("id, owner_id, title, thumbnail, diagram_path, updated_at").Where("owner_id = ?", uid).Order("updated_at desc").Limit(page.Limit).Offset(page.Offset).Find(&items).Error; err != nil {
		return nil, err
	}
	return itemsToDto(&items), nil
}

func GetItem(uid string, diagramID string) (*models.ItemDto, error) {
	var item models.Item
	if err := DB.Where("id = ?", diagramID).First(&item).Error; err != nil {
		return nil, err
	}

	text, err := decrypt(EncryptKey, item.Text)

	if err != nil {
		return nil, err
	}

	item.Text = text
	dto := models.ItemToDto(item)
	return &dto, nil
}

func Remove(uid string, diagramID string) error {
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
	return itemsToDto(&items), nil
}

func Save(item *models.Item) error {

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
