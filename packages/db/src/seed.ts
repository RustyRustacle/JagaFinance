import { prisma } from "./index";

const defaultCategories = [
  { name: "Transportasi", nameEn: "Transportation", color: "#3B82F6", icon: "car", sortOrder: 1 },
  { name: "Makanan & Minuman", nameEn: "Food & Beverages", color: "#F59E0B", icon: "utensils", sortOrder: 2 },
  { name: "Perlengkapan Kantor", nameEn: "Office Supplies", color: "#10B981", icon: "box", sortOrder: 3 },
  { name: "Utilitas", nameEn: "Utilities", color: "#8B5CF6", icon: "bolt", sortOrder: 4 },
  { name: "Marketing & Iklan", nameEn: "Marketing & Ads", color: "#EC4899", icon: "megaphone", sortOrder: 5 },
  { name: "Gaji & Upah", nameEn: "Payroll", color: "#EF4444", icon: "wallet", sortOrder: 6 },
  { name: "Sewa", nameEn: "Rent", color: "#6B7280", icon: "home", sortOrder: 7 },
  { name: "Perawatan & Servis", nameEn: "Maintenance", color: "#06B6D4", icon: "wrench", sortOrder: 8 },
  { name: "Perjalanan Dinas", nameEn: "Business Travel", color: "#84CC16", icon: "plane", sortOrder: 9 },
  { name: "Lainnya", nameEn: "Others", color: "#64748B", icon: "ellipsis", sortOrder: 10 },
];

async function main() {
  console.log("Seeding database...");

  // memakai upsert untuk Tenant berdasarkan unique slug
  const tenant = await prisma.tenant.upsert({
    where: { slug: "demo-company" },
    update: {},
    create: {
      name: "Demo Company",
      slug: "demo-company",
      industry: "retail",
      currency: "IDR",
      language: "id",
    },
  });

  console.log(`Tenant ready: ${tenant.name}`);

  // memakai upsert untuk User berdasarkan unique ID Supabase Anda
  const user = await prisma.user.upsert({
    where: { id: "09e19405-3a2f-47e1-82e7-d851d4ac5322" },
    update: { email: "admin3@gmail.com" },
    create: {
      id: "09e19405-3a2f-47e1-82e7-d851d4ac5322",
      email: "admin3@gmail.com",
      name: "Demo Admin",
    },
  });

  console.log(`User ready: ${user.email}`);

  // memakai upsert untuk TenantMember berdasarkan kombinasi unique [tenantId, userId]
  await prisma.tenantMember.upsert({
    where: {
      tenantId_userId: {
        tenantId: tenant.id,
        userId: user.id,
      },
    },
    update: {},
    create: {
      tenantId: tenant.id,
      userId: user.id,
      role: "ADMIN",
      status: "ACCEPTED",
      acceptedAt: new Date(),
    },
  });

  console.log("Admin membership ready");

  // memakai upsert untuk Expense Categories berdasarkan kombinasi unique [tenantId, name]
  for (const cat of defaultCategories) {
    await prisma.expenseCategory.upsert({
      where: {
        tenantId_name: {
          tenantId: tenant.id,
          name: cat.name,
        },
      },
      update: {},
      create: {
        ...cat,
        tenantId: tenant.id,
      },
    });
  }

  console.log(`Created/Verified ${defaultCategories.length} default categories`);
  console.log("Seeding completed successfully!");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });