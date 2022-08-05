package share

import (
	"context"

	"cloud.google.com/go/firestore"
	"firebase.google.com/go/v4/storage"
	"github.com/harehare/textusm/pkg/context/values"
	"github.com/harehare/textusm/pkg/domain/model/item/diagramitem"
	"github.com/harehare/textusm/pkg/domain/model/share"
	shareRepo "github.com/harehare/textusm/pkg/domain/repository/share"
	e "github.com/harehare/textusm/pkg/error"
	"github.com/harehare/textusm/pkg/infra/firebase"
	"github.com/samber/mo"
	"golang.org/x/crypto/bcrypt"
	"golang.org/x/sync/errgroup"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

const (
	shareCollection = "share"
	storageRoot     = shareCollection
)

type FirestoreShareRepository struct {
	client  *firestore.Client
	storage *storage.Client
}

func NewFirestoreShareRepository(client *firestore.Client, storage *storage.Client) shareRepo.ShareRepository {
	return &FirestoreShareRepository{client: client, storage: storage}
}

func (r *FirestoreShareRepository) Find(ctx context.Context, hashKey string) mo.Result[shareRepo.ShareValue] {
	return r.findFromFirestore(ctx, hashKey)
}

func (r *FirestoreShareRepository) Save(ctx context.Context, hashKey string, item *diagramitem.DiagramItem, shareInfo *share.Share) mo.Result[bool] {
	eg, ctx := errgroup.WithContext(ctx)

	eg.Go(func() error {
		return r.saveToFirestore(ctx, hashKey, item, shareInfo).Error()
	})

	eg.Go(func() error {
		return r.saveToCloudStorage(ctx, hashKey, item).Error()
	})

	if err := eg.Wait(); err != nil {
		return mo.Err[bool](err)
	}

	return mo.Ok(true)
}

func (r *FirestoreShareRepository) Delete(ctx context.Context, hashKey string) mo.Result[bool] {
	tx := values.GetTx(ctx)

	if tx.IsAbsent() {
		_, err := r.client.Collection(shareCollection).Doc(hashKey).Delete(ctx)

		if err != nil {
			return mo.Err[bool](err)
		}

		return mo.Ok(true)
	}

	ref := r.client.Collection(shareCollection).Doc(hashKey)
	err := tx.MustGet().Delete(ref)

	if err != nil {
		return mo.Err[bool](err)
	}

	return mo.Ok(true)
}

func (r *FirestoreShareRepository) findFromFirestore(ctx context.Context, hashKey string) mo.Result[shareRepo.ShareValue] {
	fields, err := r.client.Collection(shareCollection).Doc(hashKey).Get(ctx)

	if st, ok := status.FromError(err); ok && st.Code() == codes.NotFound {
		return mo.Err[shareRepo.ShareValue](e.NotFoundError(err))
	}

	if err != nil {
		return mo.Err[shareRepo.ShareValue](err)
	}

	data := fields.Data()
	item := diagramitem.MapToDiagramItem(data)

	if item.IsError() {
		return mo.Err[shareRepo.ShareValue](item.Error())
	}

	if item.MustGet().IsSaveToStorage() {
		ret := r.findFromCloudStorage(ctx, hashKey, item.MustGet().ID())
		if ret.IsError() {
			return mo.Err[shareRepo.ShareValue](ret.Error())
		}
		item = item.Map(func(i *diagramitem.DiagramItem) (*diagramitem.DiagramItem, error) {
			i.UpdateEncryptedText(ret.MustGet())
			return i, nil
		})
	}

	var (
		allowIPList    []string
		allowEmailList []string
		token          string
		expireTime     int64
	)
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

	shareInfo := share.Share{
		Token:          token,
		ExpireTime:     expireTime,
		Password:       p,
		AllowIPList:    allowIPList,
		AllowEmailList: allowEmailList,
	}
	return mo.Ok(shareRepo.ShareValue{DiagramItem: item.OrEmpty(), ShareInfo: &shareInfo})
}

func (r *FirestoreShareRepository) findFromCloudStorage(ctx context.Context, hashKey string, itemID string) mo.Result[string] {
	storage := firebase.NewCloudStorage(r.storage)
	return storage.Get(ctx, storageRoot, hashKey, itemID)
}

func (r *FirestoreShareRepository) saveToFirestore(ctx context.Context, hashKey string, item *diagramitem.DiagramItem, shareInfo *share.Share) mo.Result[bool] {
	var savePassword string

	if shareInfo.Password != "" {
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(shareInfo.Password), bcrypt.DefaultCost)

		if err != nil {
			return mo.Err[bool](err)
		}
		savePassword = string(hashedPassword)
	} else {
		savePassword = ""
	}

	v := item.ToMap()
	delete(v, "Text")
	v["password"] = savePassword
	v["allowIPList"] = shareInfo.AllowIPList
	v["token"] = shareInfo.Token
	v["expireTime"] = shareInfo.ExpireTime
	v["allowEmailList"] = shareInfo.AllowEmailList
	_, err := r.client.Collection(shareCollection).Doc(hashKey).Set(ctx, v)

	if err != nil {
		return mo.Err[bool](err)
	}

	return mo.Ok(true)
}

func (r *FirestoreShareRepository) saveToCloudStorage(ctx context.Context, hashKey string, item *diagramitem.DiagramItem) mo.Result[bool] {
	text := item.EncryptedText()
	storage := firebase.NewCloudStorage(r.storage)
	return storage.Put(ctx, &text, storageRoot, hashKey, item.ID())
}
