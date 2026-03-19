import { test, expect } from '@playwright/test'

test.describe('Homepage', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/')
  })

  test('should display hero section', async ({ page }) => {
    await expect(page.getByRole('heading', { name: 'Authentic Taste of' })).toBeVisible()
    await expect(page.getByRole('link', { name: 'Shop Pickles' })).toBeVisible()
    await expect(page.getByRole('link', { name: 'Explore Combos' })).toBeVisible()
  })

  test('should display categories section', async ({ page }) => {
    await expect(page.getByRole('heading', { name: 'Shop by Category' })).toBeVisible()
    await expect(page.getByRole('link', { name: /Pickles/ })).toBeVisible()
    await expect(page.getByRole('link', { name: /Spices/ })).toBeVisible()
    await expect(page.getByRole('link', { name: /Laddus/ })).toBeVisible()
    await expect(page.getByRole('link', { name: /Combos/ })).toBeVisible()
  })

  test('should display bestsellers section', async ({ page }) => {
    await expect(page.getByRole('heading', { name: 'Bestsellers' })).toBeVisible()
  })

  test('should display why choose us section', async ({ page }) => {
    await expect(page.getByRole('heading', { name: 'Why Choose Us' })).toBeVisible()
    await expect(page.getByText('Handmade with Love')).toBeVisible()
    await expect(page.getByText('Premium Quality')).toBeVisible()
    await expect(page.getByText('Fast Delivery')).toBeVisible()
    await expect(page.getByText('100% Authentic')).toBeVisible()
  })

  test('should have working navigation links', async ({ page }) => {
    await page.locator('nav').getByRole('link', { name: 'Products' }).click()
    await expect(page).toHaveURL('/products')
    await expect(page.getByRole('heading', { name: 'Our Products' })).toBeVisible()
  })
})
