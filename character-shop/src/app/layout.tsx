import type { Metadata, Viewport } from "next";
import "./globals.css";
import NavBar from "@/components/NavBar";
import { getCurrentUser } from "@/lib/auth";

export const metadata: Metadata = {
  title: "줄넘킹 캐릭터 상점",
  description: "줄넘킹 외부 캐릭터 구매 신청 사이트",
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
};

export default async function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const user = await getCurrentUser();

  return (
    <html lang="ko">
      <body className="min-h-screen bg-brand-bg text-white">
        <NavBar email={user?.email ?? null} isAdmin={user?.isAdmin ?? false} />
        <main className="mx-auto max-w-lg px-4 py-6">{children}</main>
      </body>
    </html>
  );
}
