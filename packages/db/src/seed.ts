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

  const tenant = await prisma.tenant.create({
    data: {
      name: "Demo Company",
      slug: "demo-company",
      industry: "retail",
      currency: "IDR",
      language: "id",
    },
  });

  console.log(`Created tenant: ${tenant.name}`);

  // const user = await prisma.user.create({
  //   data: {
  //     id: "00000000-0000-0000-0000-000000000001",
  //     email: "admin@demo.com",
  //     name: "Demo Admin",
  //   },
  // });

  const user = await prisma.user.create({
    data: {
      id: "687f5611-f739-48fa-a836-b985e689ad45",
      email: "daniel@gmail.com",
      name: "Daniel",
    },
  });

  console.log(`Created user: ${user.email}`);

  await prisma.tenantMember.create({
    data: {
      tenantId: tenant.id,
      userId: user.id,
      role: "ADMIN",
      status: "ACCEPTED",
      acceptedAt: new Date(),
    },
  });

  console.log("Created admin membership");

  for (const cat of defaultCategories) {
    await prisma.expenseCategory.create({
      data: {
        ...cat,
        tenantId: tenant.id,
      },
    });
  }

  console.log(`Created ${defaultCategories.length} default categories`);
  console.log("Seeding completed!");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
