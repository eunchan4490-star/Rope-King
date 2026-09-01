export type ItemType = "character" | "currency";

export type Item = {
  id: string;
  name: string;
  price: number;
  image_url: string | null;
  active: boolean;
  item_type: ItemType;
  currency_amount: number | null;
  created_at: string;
};

export type OrderStatus = "pending" | "approved" | "rejected";

export type Order = {
  id: string;
  user_id: string;
  item_id: string;
  price: number;
  depositor_name: string;
  status: OrderStatus;
  created_at: string;
  approved_at: string | null;
};

export type OrderWithItem = Order & {
  items: Pick<Item, "id" | "name" | "image_url" | "item_type"> | null;
};

export type RedeemCode = {
  code: string;
  currency_amount: number;
  redeemed: boolean;
};
