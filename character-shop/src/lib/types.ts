export type Item = {
  id: string;
  name: string;
  price: number;
  image_url: string | null;
  active: boolean;
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
  items: Pick<Item, "id" | "name" | "image_url"> | null;
};
