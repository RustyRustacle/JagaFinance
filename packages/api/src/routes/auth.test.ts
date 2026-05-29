import { describe, it, expect } from "vitest";
import { z } from "zod";

describe("Auth Schema Validation", () => {
  const registerSchema = z.object({
    email: z.string().email(),
    password: z.string().min(8),
    name: z.string().min(2).max(100),
    tenantName: z.string().min(2).max(100),
    tenantSlug: z.string().min(2).max(50).regex(/^[a-z0-9-]+$/),
    language: z.string().default("id"),
  });

  const loginSchema = z.object({
    email: z.string().email(),
    password: z.string().min(1),
  });

  describe("Register Schema", () => {
    it("should accept valid registration data", () => {
      const result = registerSchema.safeParse({
        email: "test@example.com",
        password: "password123",
        name: "Test User",
        tenantName: "Test Company",
        tenantSlug: "test-company",
      });
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.language).toBe("id");
      }
    });

    it("should reject invalid email", () => {
      const result = registerSchema.safeParse({
        email: "not-an-email",
        password: "password123",
        name: "Test User",
        tenantName: "Test Company",
        tenantSlug: "test-company",
      });
      expect(result.success).toBe(false);
    });

    it("should reject short password", () => {
      const result = registerSchema.safeParse({
        email: "test@example.com",
        password: "short",
        name: "Test User",
        tenantName: "Test Company",
        tenantSlug: "test-company",
      });
      expect(result.success).toBe(false);
    });

    it("should reject slug with uppercase letters", () => {
      const result = registerSchema.safeParse({
        email: "test@example.com",
        password: "password123",
        name: "Test User",
        tenantName: "Test Company",
        tenantSlug: "Test-Company",
      });
      expect(result.success).toBe(false);
    });

    it("should reject slug with special characters", () => {
      const result = registerSchema.safeParse({
        email: "test@example.com",
        password: "password123",
        name: "Test User",
        tenantName: "Test Company",
        tenantSlug: "test_company!",
      });
      expect(result.success).toBe(false);
    });

    it("should accept custom language", () => {
      const result = registerSchema.safeParse({
        email: "test@example.com",
        password: "password123",
        name: "Test User",
        tenantName: "Test Company",
        tenantSlug: "test-company",
        language: "en",
      });
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.language).toBe("en");
      }
    });
  });

  describe("Login Schema", () => {
    it("should accept valid login data", () => {
      const result = loginSchema.safeParse({
        email: "test@example.com",
        password: "password123",
      });
      expect(result.success).toBe(true);
    });

    it("should reject missing password", () => {
      const result = loginSchema.safeParse({
        email: "test@example.com",
        password: "",
      });
      expect(result.success).toBe(false);
    });

    it("should reject invalid email", () => {
      const result = loginSchema.safeParse({
        email: "",
        password: "password123",
      });
      expect(result.success).toBe(false);
    });
  });
});
