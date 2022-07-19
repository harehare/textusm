package service

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"fmt"
	"net"
	"os"
	"time"

	jwt "github.com/form3tech-oss/jwt-go"
	"github.com/harehare/textusm/pkg/context/values"
	"github.com/harehare/textusm/pkg/domain/model/item/diagramitem"
	shareModel "github.com/harehare/textusm/pkg/domain/model/share"
	itemRepo "github.com/harehare/textusm/pkg/domain/repository/item"
	shareRepo "github.com/harehare/textusm/pkg/domain/repository/share"
	userRepo "github.com/harehare/textusm/pkg/domain/repository/user"
	e "github.com/harehare/textusm/pkg/error"
	"github.com/rs/zerolog/log"
	"github.com/samber/mo"
	uuid "github.com/satori/go.uuid"
)

var (
	shareEncryptKey = []byte(os.Getenv("SHARE_ENCRYPT_KEY"))
	pubKey          = os.Getenv("ENCRYPT_PUBLIC_KEY")
	priKey          = os.Getenv("ENCRYPT_PRIVATE_KEY")
)

type Service struct {
	repo      itemRepo.ItemRepository
	shareRepo shareRepo.ShareRepository
	userRepo  userRepo.UserRepository
}

func NewService(r itemRepo.ItemRepository, s shareRepo.ShareRepository, u userRepo.UserRepository) *Service {
	return &Service{
		repo:      r,
		shareRepo: s,
		userRepo:  u,
	}
}

func isAuthenticated(ctx context.Context) error {
	userID := values.GetUID(ctx)

	if userID.IsAbsent() {
		return e.NoAuthorizationError(errors.New("not authorization"))
	}

	return nil
}

func (s *Service) Find(ctx context.Context, offset, limit int, isPublic bool, isBookmark bool, fields map[string]struct{}) mo.Result[[]*diagramitem.DiagramItem] {
	if err := isAuthenticated(ctx); err != nil {
		return mo.Err[[]*diagramitem.DiagramItem](err)
	}

	return s.repo.Find(ctx, values.GetUID(ctx).OrEmpty(), offset, limit, isPublic, isBookmark)
}

func (s *Service) FindByID(ctx context.Context, itemID string, isPublic bool) mo.Result[*diagramitem.DiagramItem] {
	if err := isAuthenticated(ctx); err != nil {
		return mo.Err[*diagramitem.DiagramItem](err)
	}

	return s.repo.FindByID(ctx, values.GetUID(ctx).OrEmpty(), itemID, isPublic)
}

func (s *Service) Save(ctx context.Context, item *diagramitem.DiagramItem, isPublic bool) mo.Result[*diagramitem.DiagramItem] {
	log.Debug().Msg(fmt.Sprintf("Save diagram ID: %v, isPublic: %v", item.ID(), isPublic))
	if err := isAuthenticated(ctx); err != nil {
		return mo.Err[*diagramitem.DiagramItem](err)
	}

	userID := values.GetUID(ctx)

	if isPublic {
		publishItem := item.Publish()
		ret := s.isPublicDiagramOwner(ctx, publishItem.ID(), userID.OrEmpty())

		if !ret.OrElse(false) {
			return mo.Err[*diagramitem.DiagramItem](e.NoAuthorizationError(ret.Error()))
		}
		return s.repo.Save(ctx, userID.OrEmpty(), item, true)
	} else {
		ret := s.repo.FindByID(ctx, userID.OrEmpty(), item.ID(), true)

		if ret.IsOk() {
			err := s.repo.Delete(ctx, userID.OrEmpty(), item.ID(), true)

			if err.IsError() {
				return mo.Err[*diagramitem.DiagramItem](err.Error())
			}
			log.Debug().Msg(fmt.Sprintf("Delete public diagram ID: %v", item.ID()))
		}
	}

	return s.repo.Save(ctx, userID.OrEmpty(), item, false)
}

func (s *Service) Delete(ctx context.Context, itemID string, isPublic bool) error {
	if err := isAuthenticated(ctx); err != nil {
		return err
	}

	userID := values.GetUID(ctx)
	shareID := itemIDToShareID(itemID)

	if shareID.IsError() {
		return shareID.Error()
	}

	if isPublic {
		ret := s.isPublicDiagramOwner(ctx, itemID, userID.OrEmpty())

		if !ret.OrElse(false) {
			return e.NoAuthorizationError(errors.New("not diagram owner"))
		}
		if err := s.repo.Delete(ctx, userID.OrEmpty(), itemID, true); err.IsError() {
			return err.Error()
		}
	}

	if err := s.shareRepo.Delete(ctx, shareID.OrEmpty()); err != nil {
		return err
	}

	return s.repo.Delete(ctx, userID.OrEmpty(), itemID, false).Error()
}

func (s *Service) Bookmark(ctx context.Context, itemID string, isBookmark bool) mo.Result[*diagramitem.DiagramItem] {
	if err := isAuthenticated(ctx); err != nil {
		return mo.Err[*diagramitem.DiagramItem](err)
	}

	return s.FindByID(ctx, itemID, false).FlatMap(func(item *diagramitem.DiagramItem) mo.Result[*diagramitem.DiagramItem] {
		return s.Save(ctx, item.Bookmark(isBookmark), false)
	})
}

func (s *Service) FindShareItem(ctx context.Context, token string, password string) mo.Result[*diagramitem.DiagramItem] {
	t, err := base64.RawURLEncoding.DecodeString(token)

	if err != nil {
		return mo.Err[*diagramitem.DiagramItem](err)
	}

	jwtTokenResult := verifyToken(ctx, string(t))

	if jwtTokenResult.IsError() {
		return mo.Err[*diagramitem.DiagramItem](jwtTokenResult.Error())
	}

	jwtToken, _ := jwtTokenResult.Get()
	claims := jwtToken.Claims.(jwt.MapClaims)
	shareResponse := s.shareRepo.Find(ctx, claims["sub"].(string))

	if shareResponse.IsError() {
		return mo.Err[*diagramitem.DiagramItem](shareResponse.Error())
	}

	ip := values.GetIP(ctx)
	shareInfo := shareResponse.OrEmpty().ShareInfo

	if ip.IsAbsent() || !shareInfo.CheckIpWithinRange(ip.OrEmpty()) {
		return mo.Err[*diagramitem.DiagramItem](e.ForbiddenError(errors.New("not allow ip address")))
	}

	uid := values.GetUID(ctx)

	if uid.IsPresent() {
		u := s.userRepo.Find(ctx, uid.OrEmpty())
		if u.IsError() {
			return mo.Err[*diagramitem.DiagramItem](e.ForbiddenError(errors.New("sign in required")))
		}

		uu, _ := u.Get()

		if !shareInfo.ValidEmail(uu.Email) {
			return mo.Err[*diagramitem.DiagramItem](e.ForbiddenError(errors.New("not allow email")))
		}
	}

	if claims["check_password"].(bool) {
		if password == "" {
			return mo.Err[*diagramitem.DiagramItem](e.ForbiddenError(errors.New("password is required")))
		}

		if err := shareInfo.ComparePassword(password); err != nil {
			return mo.Err[*diagramitem.DiagramItem](e.ForbiddenError(err))
		}
	}

	return mo.Ok(shareResponse.OrEmpty().DiagramItem)
}

func (s *Service) FindShareCondition(ctx context.Context, itemID string) mo.Result[*shareModel.ShareCondition] {
	if err := isAuthenticated(ctx); err != nil {
		return mo.Err[*shareModel.ShareCondition](err)
	}

	userID := values.GetUID(ctx)

	if userID.IsAbsent() {
		return mo.Err[*shareModel.ShareCondition](e.NoAuthorizationError(errors.New("not authorization")))
	}

	ret := s.repo.FindByID(ctx, userID.OrEmpty(), itemID, false)

	if ret.IsError() {
		return mo.Err[*shareModel.ShareCondition](ret.Error())
	}

	shareID := itemIDToShareID(itemID)

	if shareID.IsError() {
		return mo.Err[*shareModel.ShareCondition](shareID.Error())
	}

	shareResponse := s.shareRepo.Find(ctx, shareID.OrEmpty())

	if shareResponse.OrEmpty().ShareInfo == nil || shareResponse.IsError() {
		// TODO:
		return mo.Ok[*shareModel.ShareCondition](nil)
	}

	share := shareResponse.OrEmpty().ShareInfo

	return mo.Ok(&shareModel.ShareCondition{
		Token:          share.Token,
		UsePassword:    share.Password != "",
		ExpireTime:     int(share.ExpireTime),
		AllowIPList:    share.AllowIPList,
		AllowEmailList: share.AllowEmailList,
	})
}

func (s *Service) Share(ctx context.Context, itemID string, expSecond int, password string, allowIPList []string, allowEmailList []string) mo.Result[string] {
	userID := values.GetUID(ctx)

	if userID.IsAbsent() {
		return mo.Err[string](e.NoAuthorizationError(errors.New("not authorization")))
	}

	itemResult := s.repo.FindByID(ctx, userID.OrEmpty(), itemID, false)

	if itemResult.IsError() {
		return mo.Err[string](itemResult.Error())
	}

	item := itemResult.OrEmpty()
	shareID := itemIDToShareID(item.ID())

	if shareID.IsError() {
		return mo.Err[string](shareID.Error())
	}

	privateKey, err := base64.StdEncoding.DecodeString(priKey)

	if err != nil {
		return mo.Err[string](err)
	}

	signKey, err := jwt.ParseRSAPrivateKeyFromPEM(privateKey)

	if err != nil {
		return mo.Err[string](err)
	}

	now := time.Now()
	expireTime := now.Add(time.Second * time.Duration(expSecond)).Unix()
	token := jwt.New(jwt.SigningMethodRS512)
	claims := token.Claims.(jwt.MapClaims)
	claims["jti"] = uuid.NewV4().String()
	claims["sub"] = shareID.OrEmpty()
	claims["iat"] = now.Unix()
	claims["exp"] = expireTime
	claims["check_password"] = password != ""
	claims["check_email"] = len(allowEmailList) > 0

	tokenString, err := token.SignedString(signKey)

	if err != nil {
		return mo.Err[string](err)
	}

	shareInfo := shareModel.Share{
		Token:          tokenString,
		Password:       password,
		AllowIPList:    validIpList(allowIPList),
		AllowEmailList: allowEmailList,
		ExpireTime:     expireTime * int64(1000),
	}

	if err := s.shareRepo.Save(ctx, shareID.OrEmpty(), item, &shareInfo); err != nil {
		return mo.Err[string](err)
	}

	return mo.Ok(base64.RawURLEncoding.EncodeToString([]byte(tokenString)))
}

func verifyToken(ctx context.Context, token string) mo.Result[*jwt.Token] {
	publicKey, err := base64.StdEncoding.DecodeString(pubKey)

	if err != nil {
		return mo.Err[*jwt.Token](e.ForbiddenError(err))
	}

	jwtPublicKey, err := jwt.ParseRSAPublicKeyFromPEM(publicKey)
	if err != nil {
		return mo.Err[*jwt.Token](e.ForbiddenError(err))
	}

	verifiedToken, err := jwt.Parse(token, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodRSA); !ok {
			return nil, err
		}
		return jwtPublicKey, nil
	})

	if err != nil || !verifiedToken.Valid {
		return mo.Err[*jwt.Token](e.URLExpiredError(err))
	}

	return mo.Ok(verifiedToken)
}

func (s *Service) isPublicDiagramOwner(ctx context.Context, itemID string, ownerUserID string) mo.Result[bool] {
	if itemID == "" {
		return mo.Ok(true)
	}

	ret := s.repo.FindByID(ctx, ownerUserID, itemID, false)
	isOwner := ret.IsOk()

	if e.GetCode(ret.Error()) == e.NotFound {
		return mo.Ok(isOwner)
	}

	return mo.Ok(isOwner)
}

func itemIDToShareID(itemID string) mo.Result[string] {
	mac := hmac.New(sha256.New, shareEncryptKey)
	_, err := mac.Write([]byte(itemID))

	if err != nil {
		return mo.Err[string](err)
	}

	return mo.Ok(hex.EncodeToString(mac.Sum(nil)))
}

func validIpList(ipList []string) []string {
	allowIpList := []string{}
	for _, ip := range ipList {
		p := net.ParseIP(ip)
		if p != nil {
			allowIpList = append(allowIpList, ip)
			continue
		}

		_, _, err := net.ParseCIDR(ip)

		if err != nil {
			continue
		}

		allowIpList = append(allowIpList, ip)
	}
	return allowIpList
}
