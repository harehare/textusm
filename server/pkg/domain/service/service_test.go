package service

import (
	"context"
	"encoding/base64"
	"testing"
	"time"

	jwt "github.com/form3tech-oss/jwt-go"
	"github.com/harehare/textusm/pkg/context/values"
	"github.com/harehare/textusm/pkg/domain/model/item"
	sm "github.com/harehare/textusm/pkg/domain/model/share"
	um "github.com/harehare/textusm/pkg/domain/model/user"
	"github.com/stretchr/testify/mock"
	"golang.org/x/crypto/bcrypt"
)

type MockItemRepository struct {
	mock.Mock
}

type MockShareRepository struct {
	mock.Mock
}

type MockUserRepository struct {
	mock.Mock
}

func (m *MockItemRepository) FindByID(ctx context.Context, userID string, itemID string, isPublic bool) (*item.Item, error) {
	ret := m.Called(ctx, userID, itemID, isPublic)
	return ret.Get(0).(*item.Item), ret.Error(1)
}

func (m *MockItemRepository) Find(ctx context.Context, userID string, offset, limit int, isPublic bool, isBookmark bool) ([]*item.Item, error) {
	ret := m.Called(ctx, userID, offset, limit, isPublic)
	return ret.Get(0).([]*item.Item), ret.Error(1)
}

func (m *MockItemRepository) Save(ctx context.Context, userID string, i *item.Item, isPublic bool) (*item.Item, error) {
	ret := m.Called(ctx, userID, i, isPublic)
	return ret.Get(0).(*item.Item), ret.Error(1)
}

func (m *MockItemRepository) Delete(ctx context.Context, userID string, itemID string, isPublic bool) error {
	ret := m.Called(ctx, userID, itemID, isPublic)
	return ret.Error(0)
}

func (m *MockShareRepository) Find(ctx context.Context, hashKey string) (*item.Item, *sm.Share, error) {
	ret := m.Called(ctx, hashKey)
	return ret.Get(0).(*item.Item), ret.Get(1).(*sm.Share), ret.Error(2)
}

func (m *MockShareRepository) Save(ctx context.Context, hashKey string, item *item.Item, shareInfo *sm.Share) error {
	ret := m.Called(ctx, hashKey, item, shareInfo)
	return ret.Error(0)
}

func (m *MockShareRepository) Delete(ctx context.Context, hashKey string) error {
	ret := m.Called(ctx, hashKey)
	return ret.Error(0)
}

func (m *MockUserRepository) Find(ctx context.Context, uid string) (*um.User, error) {
	ret := m.Called(ctx, uid)
	return ret.Get(0).(*um.User), ret.Error(1)
}

func TestFindDiagrams(t *testing.T) {
	mockItemRepo := new(MockItemRepository)
	mockShareRepo := new(MockShareRepository)
	mockUserRepo := new(MockUserRepository)
	ctx := context.Background()
	ctx = values.WithUID(ctx, "userID")

	encryptKey = []byte("000000000X000000000X000000000X12")
	baseText := "test"
	text, err := Encrypt(encryptKey, baseText)

	if err != nil {
		t.Fatal("failed test")
	}

	i := item.Item{ID: "id", Text: text}
	items := []*item.Item{&i}

	mockItemRepo.On("Find", ctx, "userID", 0, 10, false).Return(items, nil)

	service := NewService(mockItemRepo, mockShareRepo, mockUserRepo)
	fields := make(map[string]struct{})
	_, err = service.Find(ctx, 0, 10, false, false, fields)

	if err != nil {
		t.Fatal("failed FindDiagrams")
	}
}

func TestFindDiagram(t *testing.T) {
	mockItemRepo := new(MockItemRepository)
	mockShareRepo := new(MockShareRepository)
	mockUserRepo := new(MockUserRepository)
	ctx := context.Background()
	ctx = values.WithUID(ctx, "userID")

	encryptKey = []byte("000000000X000000000X000000000X12")
	baseText := "test"
	text, err := Encrypt(encryptKey, baseText)

	if err != nil {
		t.Fatal("failed test")
	}

	item := item.Item{ID: "id", Text: text}

	mockItemRepo.On("FindByID", ctx, "userID", "testID", false).Return(&item, nil)

	service := NewService(mockItemRepo, mockShareRepo, mockUserRepo)
	diagram, err := service.FindByID(ctx, "testID", false)

	if err != nil || diagram == nil || diagram.Text != baseText {
		t.Fatal("failed FindDiagram")
	}
}

func TestSaveDiagram(t *testing.T) {
	mockItemRepo := new(MockItemRepository)
	mockShareRepo := new(MockShareRepository)
	mockUserRepo := new(MockUserRepository)
	ctx := context.Background()
	ctx = values.WithUID(ctx, "userID")

	baseText := "test"
	item := item.Item{ID: "", Text: baseText}

	mockItemRepo.On("Save", ctx, "userID", &item, false).Return(&item, nil)

	service := NewService(mockItemRepo, mockShareRepo, mockUserRepo)
	diagram, err := service.Save(ctx, &item, false)

	if err != nil || diagram == nil || diagram.Text != baseText {
		t.Fatal("failed SaveDiagram")
	}
}

func TestDeleteDiagram(t *testing.T) {
	mockItemRepo := new(MockItemRepository)
	mockShareRepo := new(MockShareRepository)
	mockUserRepo := new(MockUserRepository)
	ctx := context.Background()
	ctx = values.WithUID(ctx, "userID")
	shareEncryptKey = []byte("9cbe21a8914986ffd301e3403e14b61b52f7c348b0e3c65b762ae79118b4a4bc")
	mockItemRepo.On("Delete", ctx, "userID", "testID", false).Return(nil)
	mockShareRepo.On("Delete", ctx, "39fec4b1b30fc71f52616e4120ee953cff68fd0d0a4d37560a0567ae2941916b").Return(nil)

	service := NewService(mockItemRepo, mockShareRepo, mockUserRepo)

	if err := service.Delete(ctx, "testID", false); err != nil {
		t.Fatal("failed DeleteDiagram")
	}
}

func TestShare(t *testing.T) {
	mockItemRepo := new(MockItemRepository)
	mockShareRepo := new(MockShareRepository)
	mockUserRepo := new(MockUserRepository)
	ctx := context.Background()
	ctx = values.WithUID(ctx, "userID")

	pubKey = "LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUlJQ0lqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FnOEFNSUlDQ2dLQ0FnRUF4Rk5oV2F2WE5EdVlLNWNZSGczcApFVDNuUCtvVnpsWUYyUzBORlhYNGNXelpmUHV3NFZ3NDhOODFqLy9LaUpRVEFkaGhDelBkMmNuQTJXaDBwN3AvClJzcEhHcFJHQitJdm1CYkFyMDNDbGJpcTh5a3BvRlFpZzdCK2NIOElHb3NiVmdGQ2V6TkJmbG1Md3p2T3Nad24KbkdHVGUyUEErRjg4R3RkQUxEQ1UrSGVUK2NUUFJMTWZYNk9Pb3BjWG1tc25WaHhxVkhabWd1NmlrV0hLRHNUego3YnV3ZXlWbEJLNHgxMmQwVWZ6T25BaVRqK3A1elhXUlY4UXNVNWFJY2hNeDFlRmZJVCs1VzdqMW1jMGFqdWNFClEwYVU2VGVCT1k0MFBsWFk3ZGRHYWhwUS9oRDF1a1Z4TTJKK3UwSXpVT2lrUkJna1R3eFVsLzNTWUp3d3I1RU8KZnAvRzJMOTlHaW9nMTNBUGdlSjcza0ZUS3JtSU5kajhxM3hMdDkyTXMyTDRCSWhwOEJ1eXRZSEZXUzlDU0c5Tgo4SjRDeVdWYmoxVWQ0RmFmSWk3VTJiT2djbWcwUVhueC9xVmFQRHdoRlJiVG54aFR2Y2k1WE4rVXRKY3NhaVQzCiszaXhQWlh5Lzh5ZjlXNldJcDFKdHVGWHhpbWtUUDVIMnRKM2hxMVJOcXErZTVwVC9WQUlQSFhtVmZTd01NR0cKM1M5SVhMeU54Y05kWlBiaUdSVnVFWTArREtKN2l6aVZjWlFhay8yd2NISHVzQlUvUC92OUYzM2ExTncvVldqVwpMN3VKbjBHdUN5ckFNdEl0MFU5UXRVOVpnK1RpbnZpdmw4V2xvNUpBbVZJUWY2Zi9GWjNzWFRvRXBHUEFIWTJTCkFzTnREK29sVTJYNFFFVXptMDFnK3cwQ0F3RUFBUT09Ci0tLS0tRU5EIFBVQkxJQyBLRVktLS0tLQo="
	priKey = "LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlKSndJQkFBS0NBZ0VBeEZOaFdhdlhORHVZSzVjWUhnM3BFVDNuUCtvVnpsWUYyUzBORlhYNGNXelpmUHV3CjRWdzQ4Tjgxai8vS2lKUVRBZGhoQ3pQZDJjbkEyV2gwcDdwL1JzcEhHcFJHQitJdm1CYkFyMDNDbGJpcTh5a3AKb0ZRaWc3QitjSDhJR29zYlZnRkNlek5CZmxtTHd6dk9zWndubkdHVGUyUEErRjg4R3RkQUxEQ1UrSGVUK2NUUApSTE1mWDZPT29wY1htbXNuVmh4cVZIWm1ndTZpa1dIS0RzVHo3YnV3ZXlWbEJLNHgxMmQwVWZ6T25BaVRqK3A1CnpYV1JWOFFzVTVhSWNoTXgxZUZmSVQrNVc3ajFtYzBhanVjRVEwYVU2VGVCT1k0MFBsWFk3ZGRHYWhwUS9oRDEKdWtWeE0ySit1MEl6VU9pa1JCZ2tUd3hVbC8zU1lKd3dyNUVPZnAvRzJMOTlHaW9nMTNBUGdlSjcza0ZUS3JtSQpOZGo4cTN4THQ5Mk1zMkw0QklocDhCdXl0WUhGV1M5Q1NHOU44SjRDeVdWYmoxVWQ0RmFmSWk3VTJiT2djbWcwClFYbngvcVZhUER3aEZSYlRueGhUdmNpNVhOK1V0SmNzYWlUMyszaXhQWlh5Lzh5ZjlXNldJcDFKdHVGWHhpbWsKVFA1SDJ0SjNocTFSTnFxK2U1cFQvVkFJUEhYbVZmU3dNTUdHM1M5SVhMeU54Y05kWlBiaUdSVnVFWTArREtKNwppemlWY1pRYWsvMndjSEh1c0JVL1AvdjlGMzNhMU53L1ZXaldMN3VKbjBHdUN5ckFNdEl0MFU5UXRVOVpnK1RpCm52aXZsOFdsbzVKQW1WSVFmNmYvRlozc1hUb0VwR1BBSFkyU0FzTnREK29sVTJYNFFFVXptMDFnK3cwQ0F3RUEKQVFLQ0FnQS9TVG1LZEhCczhBRC9uRGMwQ1B2bWlQUHdrSDd6QXB2a0JEZkJnVVBUSEdtSGRvTHdRcEJBWlZPWQoxYlh1RFAyTGpMckxwNjZPTkJFc2hCV0d0QUd2U2lsZGtncDVKQnAvaG1ZYW5KQnJQeG9zUkVxYzJrSTkvVGprCi9xNFlFRnVCZitwMFdITjJUVnRXVmdNdEVjOWJBOEZNOXowUFUzUEdtemllaGhLZmZieC91VWV2TjZhWFo5dmsKNFp2RU5XSjZ5YklsQS8zTG15MWdmQXRzYzJUR2I4aFdDaG5rUmxyZXV3U3VJVFpnNmdyWFM1aHorTUFmY0tkeApVb2N0YnE2VDZaQ0c0VW5aSFdoZWFkVnoxMWh5YjJBMVJhVXNib0M4ejJPY1Y5YmxBUksyczdUaWxOd0cybXRMCjVlMHcyYTJLSGRZbWZTMFB5Y3gxUkNRVmxFYjlUY2c3dnhnZUR1VU5XRW9NcUdxL1grWHJ6SHAxNlBKU1VITTkKMFdadHpHQW9WL3hkQ1lST1owMVJDbEQ1VnprajR3dksxekFEalE1VzZwdUJLMkIweFZQUnVsTlJndGZQNnBXego0a0NzTGhqNVFacXNoTW9lLzkzT0hpQmtWK082M2dlNTBCTFNjWFhHWEdhVHByWjFNb2s2YzZZTFdTb0x6amdSClFZMW9BU0dPU0NscWdoTkNFYlc1c3ZRR2wwc3lNTFV0cnU1Z2oxK1BVcGtpcGJZOER5MXFuQTVUMGRGanZVaisKZ2ZyVnNJNzVMckxwRkNMcFYza3hheEhJMmN3UUJNNVZRZVF4Z0hmWmkyOHNQTlF2QlQ2eWxjdnpVaUNBYXk0cQpnM3djKzFYUDUyZk5tMnhIMWd2UGFlbWhWdWlKZU84WWMzYUkxWFlKdXZhTno5akhLUUtDQVFFQTZxa1p2YzlHCldRUHE2c1podnpMdkI5Tnp5VHJFeTFVOVVVYmpPRkF5aW1VRm91ckJCcndhaXZNQlRtY0wvWk84VVlBN0llZUEKZjJVclFic0lpU29QT3dTcDZTMC94enptUUc5MWdvTllqaTY1dHhjUEdQeW15dEZmcUJCWld0SmRhZk90akZJNgpDaFQ3dW0rbE5GeXQya1ZOckdNbWJhWGw3VldRQ1NhRUlGbXpvWEdlVDVnSFBFZjVJdzVFR2lmRzdWMWNHRkdXCnNmQnNMMFo4VmFZdlliMXJDektNVG9UTHR0eWdSUUdhaVlLVnE4c1J0MzN2aU1uYS9yWnFTb3ZZTU1JdlYxVnMKdDM3SHlhbGwzeUwza2ZyY1FINXF5ZVpMcTNpeS9zMW81Q2dGakMxdUc1MkllbWR6Q0JqQnhMS1lkVThaSXVkTwpWcHBaRTAzQ2QvTHRUd0tDQVFFQTFpM1lIMnJzWVNHZmFVQ2hzZ1BqMDNuT0I4Smx5bjZhT0FucXQxeU5haHZ4Ckp6Y0w2dVg3RUJRWEU3UFBIWWI3TEdiYkdqNFp4cjdLY2lUdTFpU01hQktmR2FNdXM1YU1uMysvRjJhazBuT2IKMTVxd3h2aWw5dkdNbEdQTURlSm5NUFF4QXpLcUIvTm9sRVR0Mk41WmdIWjZrQnFPT3Q3VEZWQ0FoWmtGNFU3QwpGaDJ4QzVDMHZhSFBxYklZVmFDbWUvNTFldERaejNxMGRUT1VDYzlITU5jMEFSWU4zYXFBSHc2TXdjMnhBU2lpCmN6SUZPVjlwOGkwQmVONjh5UGhoTFdVdmZxQTMxRFNmSDhaUjhVQ0dpY0JmNWlMTmhTUEREZHRYcDJtV0ZISHoKUDFQY0Q2Qnc2eGpNOUJ0YjRBVG5MRTAwM092UEtRV00xU3RTSnVjUzR3S0NBUUE2V3pkRmxzaGQxcldURVNhNQp6OGJWNFdZSUF3OXhxWThJS1dMVVhFMVZVVzRuWjgzOUNNWnBDNm1sZjhiaGx0M2NQdEYxeXdhUHArOHI5NEZWCjZ4bkNpWlJmb3BzYnh5OVRrdVJjUXFIQktpbVJPTERPZS9aV3RkN2VBc0xWN1Q3QjNKR3FOY0N0UlM2YzNLcnUKN0tWbmhKaWVhRUhrUHIrQldDZnJ2cUpaRVRXMHpuYWFRS3A3K1VJaHo2aHNBTHhkeHp2aDZGaGJnL2pEZ1BubQpxdDlacFN0N3EyUnRHbVUyNG9NUTVpY3lUMEU5YWRETUd3dDRyd3BCRWNnNUpiSHIzajY3cjBqTUVVRktDMUNFClAwUG1EOGE2V3pYZlkrQXBrbWloS1NBT3JVMUQ0UUJpNmJoSkNIVDQ3SDh6bFY2SXZkVDRjeUZ1TkJBMjFyMm4KNnNmTkFvSUJBREU1UEJDTWJHTXViUXF0bGZ2cHRQU25hOWlRcndCSTlIeW9tczhsY0VMUXhTMjBFd01iZEFZUAo5L1hKUDNLVDBTbzFRV25ZbCtmN2RWK2lhVm5COEpzQ25Kb3h6TXZ0YjhoQWZkU00vSmg1aFhtWnpjTU01bWZJCnYveGlxMFVOb1pXNHFZTUlvOWRMODk4UHNISkZOK0MwV2hyQVg2dmNCanRCMHlmaE1WN0UwUXB3TEg1eDlYZ1gKdGpoVC9BL0I2a0ZaQy9yOEFQTVVTbUVkUjRxeG5yVDA0TGpYTHJ5aE1PenlWUnM5Z002NVhneUhsSGZKRy9wUwpxYUh6M3dONVFpeENzeFd4RU9PdWJGdkxJbzRGdkdYd1ZwbjNxYkJOdGNoN2ZydTFJbzcwV1dsV2hwNzR5cnJkCmFrMDM5SGVaNk45ZnB5U1c5WGVDRlFudytPS0QvTzBDZ2dFQVI2aHJkNllPd1NBYVJadlpXVUUwQklPdFRsdTkKMnMrbTNQYldtb0YzRFRrckpqdVNHZVlEVkNzbnkzaG5PYy9Cc0kwaVRrYVZ0alppLzd2MXM5MnVqbEY3SE1SeQpiYzVkOUc3K00vd1hoeCtEWlZ5RTFwOHF2N3FYQ0RhQUFodGdTR2RxWVhvazdZR0NGQWNidkNLSGJNR1FRMGhXCkJ4TUJqZit4UjJpSW5ISGNOQmNDcExTaUtRekVQUVE5QTdDbGhYdGFiUFgxQUVvdmoyczNEVW5IbVBKZFNkZGEKaG9kbi83azdRcVo0UHJGbXpTREFJSWI1SVFtQlB2ZEw3UVhhUTZOQ2preXIxZ2l5RDB0L1BSUTlSZnNaNDk3UgpTRUxDOGJvaGFuMUNTWUIwMjgyZDYxS3g4aXkya3UrV2FkMm5rN0JxeUFiNC9JVHRZeFJzamQ0aFh3PT0KLS0tLS1FTkQgUlNBIFBSSVZBVEUgS0VZLS0tLS0K"
	tests := []struct {
		key       string
		id        string
		hashKey   string
		signedKey string
	}{
		{
			key:     "9cbe21a8914986ffd301e3403e14b61b52f7c348b0e3c65b762ae79118b4a4bc",
			id:      "testID",
			hashKey: "39fec4b1b30fc71f52616e4120ee953cff68fd0d0a4d37560a0567ae2941916b",
		},
		{
			key:     "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08",
			id:      "testID2",
			hashKey: "1cbe80c449480735b0073dd20c435f8c6eb9950ae5c2d4fb7267c1b0ab5ad072",
		},
	}

	for _, test := range tests {
		shareEncryptKey = []byte(test.key)
		item := item.Item{ID: test.id, Text: ""}
		a := []string{}
		mockItemRepo.On("FindByID", ctx, "userID", test.id, false).Return(&item, nil)
		mockShareRepo.On("Save", ctx, test.hashKey, &item, mock.Anything).Return(nil)

		service := NewService(mockItemRepo, mockShareRepo, mockUserRepo)
		shareToken, err := service.Share(ctx, test.id, 1, "password", a, a)

		if err != nil {
			t.Fatal("failed ShareDiagram")
		}

		decoded, err := base64.RawURLEncoding.DecodeString(*shareToken)

		if err != nil {
			t.Fatal("decode failed")
		}

		verifiedToken, err := verifyToken(context.Background(), string(decoded))

		if err != nil || !verifiedToken.Valid {
			t.Fatal("invalid token")
		}

		claims := verifiedToken.Claims.(jwt.MapClaims)

		if claims["sub"] != test.hashKey {
			t.Fatal("invalid sub")
		}
	}
}

func TestFindShareItem(t *testing.T) {
	mockItemRepo := new(MockItemRepository)
	mockShareRepo := new(MockShareRepository)
	mockUserRepo := new(MockUserRepository)
	ctx := context.Background()
	ctx = values.WithUID(ctx, "userID")
	pubKey = "LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUlJQ0lqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FnOEFNSUlDQ2dLQ0FnRUF4Rk5oV2F2WE5EdVlLNWNZSGczcApFVDNuUCtvVnpsWUYyUzBORlhYNGNXelpmUHV3NFZ3NDhOODFqLy9LaUpRVEFkaGhDelBkMmNuQTJXaDBwN3AvClJzcEhHcFJHQitJdm1CYkFyMDNDbGJpcTh5a3BvRlFpZzdCK2NIOElHb3NiVmdGQ2V6TkJmbG1Md3p2T3Nad24KbkdHVGUyUEErRjg4R3RkQUxEQ1UrSGVUK2NUUFJMTWZYNk9Pb3BjWG1tc25WaHhxVkhabWd1NmlrV0hLRHNUego3YnV3ZXlWbEJLNHgxMmQwVWZ6T25BaVRqK3A1elhXUlY4UXNVNWFJY2hNeDFlRmZJVCs1VzdqMW1jMGFqdWNFClEwYVU2VGVCT1k0MFBsWFk3ZGRHYWhwUS9oRDF1a1Z4TTJKK3UwSXpVT2lrUkJna1R3eFVsLzNTWUp3d3I1RU8KZnAvRzJMOTlHaW9nMTNBUGdlSjcza0ZUS3JtSU5kajhxM3hMdDkyTXMyTDRCSWhwOEJ1eXRZSEZXUzlDU0c5Tgo4SjRDeVdWYmoxVWQ0RmFmSWk3VTJiT2djbWcwUVhueC9xVmFQRHdoRlJiVG54aFR2Y2k1WE4rVXRKY3NhaVQzCiszaXhQWlh5Lzh5ZjlXNldJcDFKdHVGWHhpbWtUUDVIMnRKM2hxMVJOcXErZTVwVC9WQUlQSFhtVmZTd01NR0cKM1M5SVhMeU54Y05kWlBiaUdSVnVFWTArREtKN2l6aVZjWlFhay8yd2NISHVzQlUvUC92OUYzM2ExTncvVldqVwpMN3VKbjBHdUN5ckFNdEl0MFU5UXRVOVpnK1RpbnZpdmw4V2xvNUpBbVZJUWY2Zi9GWjNzWFRvRXBHUEFIWTJTCkFzTnREK29sVTJYNFFFVXptMDFnK3cwQ0F3RUFBUT09Ci0tLS0tRU5EIFBVQkxJQyBLRVktLS0tLQo="
	priKey = "LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlKSndJQkFBS0NBZ0VBeEZOaFdhdlhORHVZSzVjWUhnM3BFVDNuUCtvVnpsWUYyUzBORlhYNGNXelpmUHV3CjRWdzQ4Tjgxai8vS2lKUVRBZGhoQ3pQZDJjbkEyV2gwcDdwL1JzcEhHcFJHQitJdm1CYkFyMDNDbGJpcTh5a3AKb0ZRaWc3QitjSDhJR29zYlZnRkNlek5CZmxtTHd6dk9zWndubkdHVGUyUEErRjg4R3RkQUxEQ1UrSGVUK2NUUApSTE1mWDZPT29wY1htbXNuVmh4cVZIWm1ndTZpa1dIS0RzVHo3YnV3ZXlWbEJLNHgxMmQwVWZ6T25BaVRqK3A1CnpYV1JWOFFzVTVhSWNoTXgxZUZmSVQrNVc3ajFtYzBhanVjRVEwYVU2VGVCT1k0MFBsWFk3ZGRHYWhwUS9oRDEKdWtWeE0ySit1MEl6VU9pa1JCZ2tUd3hVbC8zU1lKd3dyNUVPZnAvRzJMOTlHaW9nMTNBUGdlSjcza0ZUS3JtSQpOZGo4cTN4THQ5Mk1zMkw0QklocDhCdXl0WUhGV1M5Q1NHOU44SjRDeVdWYmoxVWQ0RmFmSWk3VTJiT2djbWcwClFYbngvcVZhUER3aEZSYlRueGhUdmNpNVhOK1V0SmNzYWlUMyszaXhQWlh5Lzh5ZjlXNldJcDFKdHVGWHhpbWsKVFA1SDJ0SjNocTFSTnFxK2U1cFQvVkFJUEhYbVZmU3dNTUdHM1M5SVhMeU54Y05kWlBiaUdSVnVFWTArREtKNwppemlWY1pRYWsvMndjSEh1c0JVL1AvdjlGMzNhMU53L1ZXaldMN3VKbjBHdUN5ckFNdEl0MFU5UXRVOVpnK1RpCm52aXZsOFdsbzVKQW1WSVFmNmYvRlozc1hUb0VwR1BBSFkyU0FzTnREK29sVTJYNFFFVXptMDFnK3cwQ0F3RUEKQVFLQ0FnQS9TVG1LZEhCczhBRC9uRGMwQ1B2bWlQUHdrSDd6QXB2a0JEZkJnVVBUSEdtSGRvTHdRcEJBWlZPWQoxYlh1RFAyTGpMckxwNjZPTkJFc2hCV0d0QUd2U2lsZGtncDVKQnAvaG1ZYW5KQnJQeG9zUkVxYzJrSTkvVGprCi9xNFlFRnVCZitwMFdITjJUVnRXVmdNdEVjOWJBOEZNOXowUFUzUEdtemllaGhLZmZieC91VWV2TjZhWFo5dmsKNFp2RU5XSjZ5YklsQS8zTG15MWdmQXRzYzJUR2I4aFdDaG5rUmxyZXV3U3VJVFpnNmdyWFM1aHorTUFmY0tkeApVb2N0YnE2VDZaQ0c0VW5aSFdoZWFkVnoxMWh5YjJBMVJhVXNib0M4ejJPY1Y5YmxBUksyczdUaWxOd0cybXRMCjVlMHcyYTJLSGRZbWZTMFB5Y3gxUkNRVmxFYjlUY2c3dnhnZUR1VU5XRW9NcUdxL1grWHJ6SHAxNlBKU1VITTkKMFdadHpHQW9WL3hkQ1lST1owMVJDbEQ1VnprajR3dksxekFEalE1VzZwdUJLMkIweFZQUnVsTlJndGZQNnBXego0a0NzTGhqNVFacXNoTW9lLzkzT0hpQmtWK082M2dlNTBCTFNjWFhHWEdhVHByWjFNb2s2YzZZTFdTb0x6amdSClFZMW9BU0dPU0NscWdoTkNFYlc1c3ZRR2wwc3lNTFV0cnU1Z2oxK1BVcGtpcGJZOER5MXFuQTVUMGRGanZVaisKZ2ZyVnNJNzVMckxwRkNMcFYza3hheEhJMmN3UUJNNVZRZVF4Z0hmWmkyOHNQTlF2QlQ2eWxjdnpVaUNBYXk0cQpnM3djKzFYUDUyZk5tMnhIMWd2UGFlbWhWdWlKZU84WWMzYUkxWFlKdXZhTno5akhLUUtDQVFFQTZxa1p2YzlHCldRUHE2c1podnpMdkI5Tnp5VHJFeTFVOVVVYmpPRkF5aW1VRm91ckJCcndhaXZNQlRtY0wvWk84VVlBN0llZUEKZjJVclFic0lpU29QT3dTcDZTMC94enptUUc5MWdvTllqaTY1dHhjUEdQeW15dEZmcUJCWld0SmRhZk90akZJNgpDaFQ3dW0rbE5GeXQya1ZOckdNbWJhWGw3VldRQ1NhRUlGbXpvWEdlVDVnSFBFZjVJdzVFR2lmRzdWMWNHRkdXCnNmQnNMMFo4VmFZdlliMXJDektNVG9UTHR0eWdSUUdhaVlLVnE4c1J0MzN2aU1uYS9yWnFTb3ZZTU1JdlYxVnMKdDM3SHlhbGwzeUwza2ZyY1FINXF5ZVpMcTNpeS9zMW81Q2dGakMxdUc1MkllbWR6Q0JqQnhMS1lkVThaSXVkTwpWcHBaRTAzQ2QvTHRUd0tDQVFFQTFpM1lIMnJzWVNHZmFVQ2hzZ1BqMDNuT0I4Smx5bjZhT0FucXQxeU5haHZ4Ckp6Y0w2dVg3RUJRWEU3UFBIWWI3TEdiYkdqNFp4cjdLY2lUdTFpU01hQktmR2FNdXM1YU1uMysvRjJhazBuT2IKMTVxd3h2aWw5dkdNbEdQTURlSm5NUFF4QXpLcUIvTm9sRVR0Mk41WmdIWjZrQnFPT3Q3VEZWQ0FoWmtGNFU3QwpGaDJ4QzVDMHZhSFBxYklZVmFDbWUvNTFldERaejNxMGRUT1VDYzlITU5jMEFSWU4zYXFBSHc2TXdjMnhBU2lpCmN6SUZPVjlwOGkwQmVONjh5UGhoTFdVdmZxQTMxRFNmSDhaUjhVQ0dpY0JmNWlMTmhTUEREZHRYcDJtV0ZISHoKUDFQY0Q2Qnc2eGpNOUJ0YjRBVG5MRTAwM092UEtRV00xU3RTSnVjUzR3S0NBUUE2V3pkRmxzaGQxcldURVNhNQp6OGJWNFdZSUF3OXhxWThJS1dMVVhFMVZVVzRuWjgzOUNNWnBDNm1sZjhiaGx0M2NQdEYxeXdhUHArOHI5NEZWCjZ4bkNpWlJmb3BzYnh5OVRrdVJjUXFIQktpbVJPTERPZS9aV3RkN2VBc0xWN1Q3QjNKR3FOY0N0UlM2YzNLcnUKN0tWbmhKaWVhRUhrUHIrQldDZnJ2cUpaRVRXMHpuYWFRS3A3K1VJaHo2aHNBTHhkeHp2aDZGaGJnL2pEZ1BubQpxdDlacFN0N3EyUnRHbVUyNG9NUTVpY3lUMEU5YWRETUd3dDRyd3BCRWNnNUpiSHIzajY3cjBqTUVVRktDMUNFClAwUG1EOGE2V3pYZlkrQXBrbWloS1NBT3JVMUQ0UUJpNmJoSkNIVDQ3SDh6bFY2SXZkVDRjeUZ1TkJBMjFyMm4KNnNmTkFvSUJBREU1UEJDTWJHTXViUXF0bGZ2cHRQU25hOWlRcndCSTlIeW9tczhsY0VMUXhTMjBFd01iZEFZUAo5L1hKUDNLVDBTbzFRV25ZbCtmN2RWK2lhVm5COEpzQ25Kb3h6TXZ0YjhoQWZkU00vSmg1aFhtWnpjTU01bWZJCnYveGlxMFVOb1pXNHFZTUlvOWRMODk4UHNISkZOK0MwV2hyQVg2dmNCanRCMHlmaE1WN0UwUXB3TEg1eDlYZ1gKdGpoVC9BL0I2a0ZaQy9yOEFQTVVTbUVkUjRxeG5yVDA0TGpYTHJ5aE1PenlWUnM5Z002NVhneUhsSGZKRy9wUwpxYUh6M3dONVFpeENzeFd4RU9PdWJGdkxJbzRGdkdYd1ZwbjNxYkJOdGNoN2ZydTFJbzcwV1dsV2hwNzR5cnJkCmFrMDM5SGVaNk45ZnB5U1c5WGVDRlFudytPS0QvTzBDZ2dFQVI2aHJkNllPd1NBYVJadlpXVUUwQklPdFRsdTkKMnMrbTNQYldtb0YzRFRrckpqdVNHZVlEVkNzbnkzaG5PYy9Cc0kwaVRrYVZ0alppLzd2MXM5MnVqbEY3SE1SeQpiYzVkOUc3K00vd1hoeCtEWlZ5RTFwOHF2N3FYQ0RhQUFodGdTR2RxWVhvazdZR0NGQWNidkNLSGJNR1FRMGhXCkJ4TUJqZit4UjJpSW5ISGNOQmNDcExTaUtRekVQUVE5QTdDbGhYdGFiUFgxQUVvdmoyczNEVW5IbVBKZFNkZGEKaG9kbi83azdRcVo0UHJGbXpTREFJSWI1SVFtQlB2ZEw3UVhhUTZOQ2preXIxZ2l5RDB0L1BSUTlSZnNaNDk3UgpTRUxDOGJvaGFuMUNTWUIwMjgyZDYxS3g4aXkya3UrV2FkMm5rN0JxeUFiNC9JVHRZeFJzamQ0aFh3PT0KLS0tLS1FTkQgUlNBIFBSSVZBVEUgS0VZLS0tLS0K"
	encryptKey = []byte("000000000X000000000X000000000X12")
	tests := []struct {
		inputPassword  string
		hashedPassword string
		allowIPList    []string
		ip             string
		allowEmailList []string
		email          string
		isErr          bool
	}{
		{
			inputPassword:  "",
			hashedPassword: genPassword("1234"),
			allowIPList:    []string{},
			ip:             "127.0.0.1",
			allowEmailList: []string{},
			email:          "test@textusm.com",
			isErr:          false,
		},
		{
			inputPassword:  "1234",
			hashedPassword: genPassword("1234"),
			allowIPList:    []string{},
			ip:             "127.0.0.1",
			allowEmailList: []string{},
			email:          "test@textusm.com",
			isErr:          false,
		},
		{
			inputPassword:  "12345",
			hashedPassword: genPassword("1234"),
			allowIPList:    []string{},
			ip:             "127.0.0.1",
			allowEmailList: []string{},
			email:          "test@textusm.com",
			isErr:          true,
		},
		{
			inputPassword:  "1234",
			hashedPassword: genPassword("1234"),
			allowIPList:    []string{"192.168.0.1"},
			ip:             "127.0.0.1",
			allowEmailList: []string{},
			email:          "test@textusm.com",
			isErr:          true,
		},
		{
			inputPassword:  "1234",
			hashedPassword: genPassword("1234"),
			allowIPList:    []string{"192.168.0.1"},
			ip:             "192.168.0.1",
			allowEmailList: []string{},
			email:          "test@textusm.com",
			isErr:          false,
		},
		{
			inputPassword:  "1234",
			hashedPassword: genPassword("1234"),
			allowIPList:    []string{"192.168.0.1"},
			ip:             "192.168.0.1",
			allowEmailList: []string{"test1@textusm.com"},
			email:          "test@textusm.com",
			isErr:          true,
		},
		{
			inputPassword:  "1234",
			hashedPassword: genPassword("1234"),
			allowIPList:    []string{"192.168.0.1"},
			ip:             "192.168.0.1",
			allowEmailList: []string{"test@textusm.com"},
			email:          "test@textusm.com",
			isErr:          false,
		},
	}

	itemID := "testID"
	token := "testToken"
	expireTime := time.Now().Add(time.Hour * 2).Unix()

	for _, test := range tests {
		ctx = values.WithIP(ctx, test.ip)
		text, _ := Encrypt(encryptKey, "test")
		item := item.Item{ID: itemID, Text: text}
		shareInfo := sm.Share{
			Token:          token,
			Password:       test.hashedPassword,
			AllowIPList:    test.allowIPList,
			ExpireTime:     expireTime,
			AllowEmailList: test.allowEmailList,
		}
		user := um.User{
			UID:   "userID",
			Name:  "test",
			Email: test.email,
		}
		mockItemRepo.On("FindByID", ctx, "userID", itemID, false).Return(&item, nil)
		mockShareRepo.On("Find", ctx, "9ccb761f669123b71cff48beb77555a68e5819995ac6eb8495efa2ed01e298f7").Return(&item, &shareInfo, nil)
		mockShareRepo.On("Save", ctx, "9ccb761f669123b71cff48beb77555a68e5819995ac6eb8495efa2ed01e298f7", &item, mock.Anything).Return(nil)
		mockUserRepo.On("Find", ctx, "userID").Return(&user, nil)
		service := NewService(mockItemRepo, mockShareRepo, mockUserRepo)
		shareId, _ := service.Share(ctx, itemID, int(expireTime), test.inputPassword, test.allowIPList, test.allowEmailList)
		_, err := service.FindShareItem(ctx, *shareId, test.inputPassword)

		if err == nil && test.isErr {
			t.Fatal("test failed")
		} else if err != nil && !test.isErr {
			t.Fatal(err.Error())
		}
	}
}

func genPassword(password string) string {
	p, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(p)
}
