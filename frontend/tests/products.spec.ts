import { test, expect } from '@playwright/test'

test.describe('Products Page', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/products')
  })

  test('should display products page title', async ({ page }) => {
    await expect(page.getByRole('heading', { name: 'Our Products' })).toBeVisible()
  })

  test('should display products grid', async ({ page }) => {
    await expect(page.getByRole('link', { name: 'Mango Pickle' }).first()).toBeVisible()
  })

  test('should filter products by category', async ({ page }) => {
    await page.locator('select').first().selectOption('pickle')
    await expect(page.getByRole('link', { name: 'Mango Pickle' }).first()).toBeVisible()
    await expect(page.getByRole('link', { name: 'Garam Masala' })).not.toBeVisible()
  })

  test('should search products', async ({ page }) => {
    await page.getByPlaceholder('Search products...').fill('mango')
    await expect(page.getByRole('link', { name: 'Mango Pickle' }).first()).toBeVisible()
  })

  test('should navigate to product detail page', async ({ page }) => {
    await page.getByRole('link', { name: 'Mango Pickle' }).first().click()
    await expect(page).toHaveURL('/products/1')
    await expect(page.getByRole('heading', { name: 'Mango Pickle' })).toBeVisible()
  })
})
