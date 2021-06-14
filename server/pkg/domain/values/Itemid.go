package values

type ItemID string

func NewItemID(s string) ItemID {
	return ItemID(s)
}

func (i ItemID) String() string {
	return string(i)
}
