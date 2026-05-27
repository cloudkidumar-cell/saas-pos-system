import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "POS Admin Panel",
  description: "POS System Admin Panel",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="bg-gray-100 text-gray-900">
        {children}
      </body>
    </html>
  );
}