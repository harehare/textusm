package repository

import (
	"context"

	"cloud.google.com/go/firestore"
	e "github.com/harehare/textusm/pkg/error"
	"github.com/harehare/textusm/pkg/item"
	"github.com/harehare/textusm/pkg/model"
	"github.com/harehare/textusm/pkg/values"
	"golang.org/x/crypto/bcrypt"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

const (
	shareCollection = "share"
)

type FirestoreShareRepository struct {
	client *firestore.Client
}

func NewFirestoreShareRepository(client *firestore.Client) ShareRepository {
	return &FirestoreShareRepository{client: client}
}

func (r *FirestoreShareRepository) Find(ctx context.Context, hashKey string) (*item.Item, *model.Share, error) {
	fields, err := r.client.Collection(shareCollection).Doc(hashKey).Get(ctx)

	if st, ok := status.FromError(err); ok && st.Code() == codes.NotFound {
		return nil, nil, e.NotFoundError(err)
	}

	if err != nil {
		return nil, nil, err
	}

	var i item.Item

	if err := fields.DataTo(&i); err != nil {
		return nil, nil, err
	}

	var (
		allowIPList    []string
		allowEmailList []string
		token          string
		expireTime     int64
	)
	data := fields.Data()
	p := data["password"].(string)

	if v, ok := data["allowIPList"]; ok {
		for _, ip := range v.([]interface{}) {
			allowIPList = append(allowIPList, ip.(string))
		}
	}

	if v, ok := data["allowEmailList"]; ok {
		for _, e := range v.([]interface{}) {
			allowEmailList = append(allowEmailList, e.(string))
		}
	}

	if v, ok := data["token"]; ok {
		token = v.(string)
	}

	if v, ok := data["expireTime"]; ok {
		expireTime = v.(int64)
	}

	shareInfo := model.Share{
		Token:          token,
		ExpireTime:     expireTime,
		Password:       p,
		AllowIPList:    allowIPList,
		AllowEmailList: allowEmailList,
	}
	return &i, &shareInfo, nil
}

func (r *FirestoreShareRepository) Save(ctx context.Context, hashKey string, item *item.Item, shareInfo *model.Share) error {
	var savePassword string

	if shareInfo.Password != "" {
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(shareInfo.Password), bcrypt.DefaultCost)

		if err != nil {
			return err
		}
		savePassword = string(hashedPassword)
	} else {
		savePassword = ""
	}

	v := map[string]interface{}{
		"id":             item.ID,
		"title":          item.Title,
		"text":           item.Text,
		"thumbnail":      item.Thumbnail,
		"diagram":        item.Diagram,
		"isPublic":       item.IsPublic,
		"isBookmark":     item.IsBookmark,
		"tags":           item.Tags,
		"createdAt":      item.CreatedAt,
		"updatedAt":      item.UpdatedAt,
		"password":       savePassword,
		"allowIPList":    shareInfo.AllowIPList,
		"token":          shareInfo.Token,
		"expireTime":     shareInfo.ExpireTime,
		"allowEmailList": shareInfo.AllowEmailList}
	_, err := r.client.Collection(shareCollection).Doc(hashKey).Set(ctx, v)
	return err
}

func (r *FirestoreShareRepository) Delete(ctx context.Context, hashKey string) error {
	tx := values.GetTx(ctx)

	if tx == nil {
		_, err := r.client.Collection(shareCollection).Doc(hashKey).Delete(ctx)
		return err
	}

	ref := r.client.Collection(shareCollection).Doc(hashKey)
	return tx.Delete(ref)
}
