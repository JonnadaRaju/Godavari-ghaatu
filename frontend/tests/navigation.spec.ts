import { test, expect } from '@playwright/test'

test.describe('Navigation', () => {
  test('should have working navbar', async ({ page }) => {
    await page.goto('/')
    await expect(page.getByRole('link', { name: 'Godavari Ghaatu' }).first()).toBeVisible()
  })

  test('should navigate to home from logo', async ({ page }) => {
    await page.goto('/products')
    await page.getByRole('link', { name: 'Godavari Ghaatu' }).first().click()
    await expect(page).toHaveURL('/')
  })

  test('should display cart icon', async ({ page }) => {
    await page.goto('/')
    await expect(page.getByRole('button').filter({ has: page.locator('svg') }).first()).toBeVisible()
  })

  test('should display login button when not authenticated', async ({ page }) => {
    await page.goto('/')
    await expect(page.getByRole('button', { name: 'Login' })).toBeVisible()
  })

  test('should have working footer links', async ({ page }) => {
    await page.goto('/')
    await expect(page.getByRole('heading', { name: 'Quick Links' })).toBeVisible()
    await expect(page.getByRole('heading', { name: 'Categories' })).toBeVisible()
    await expect(page.getByRole('heading', { name: 'Contact' })).toBeVisible()
  })
})
