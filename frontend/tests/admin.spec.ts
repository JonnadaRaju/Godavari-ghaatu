import { test, expect } from '@playwright/test'

test.describe('Admin Panel', () => {
  test('should redirect to admin login when not authenticated', async ({ page }) => {
    await page.goto('/admin')
    await expect(page).toHaveURL('/admin/login')
  })

  test('should have admin login page accessible', async ({ page }) => {
    await page.goto('/admin/login')
    await page.waitForTimeout(1000)
    const url = page.url()
    expect(url).toContain('/admin/login')
  })
})
