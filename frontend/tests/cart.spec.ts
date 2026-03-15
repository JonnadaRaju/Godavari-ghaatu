import { test, expect } from '@playwright/test'

test.describe('Cart Functionality', () => {
  test('should add product to cart from homepage', async ({ page }) => {
    await page.goto('/')
    await page.getByRole('link', { name: 'Mango Pickle' }).first().getByRole('button', { name: 'Add' }).click()
    await expect(page.getByText('added to cart')).toBeVisible()
  })

  test('should open cart sidebar', async ({ page }) => {
    await page.goto('/')
    await page.locator('nav').getByRole('button').filter({ has: page.locator('svg') }).first().click()
    await expect(page.getByText('Shopping Cart')).toBeVisible()
  })

  test('should display cart items', async ({ page }) => {
    await page.goto('/')
    await page.getByRole('link', { name: 'Mango Pickle' }).first().getByRole('button', { name: 'Add' }).click()
    await page.locator('nav').getByRole('button').filter({ has: page.locator('svg') }).first().click()
    await expect(page.getByRole('heading', { name: 'Mango Pickle' }).nth(1)).toBeVisible()
  })

  test('should calculate delivery fee', async ({ page }) => {
    await page.goto('/')
    await page.getByRole('link', { name: 'Mango Pickle' }).first().getByRole('button', { name: 'Add' }).click()
    await page.locator('nav').getByRole('button').filter({ has: page.locator('svg') }).first().click()
    await expect(page.getByText('Free')).toBeVisible()
  })

  test('should navigate to checkout', async ({ page }) => {
    await page.goto('/')
    await page.getByRole('link', { name: 'Mango Pickle' }).first().getByRole('button', { name: 'Add' }).click()
    await page.locator('nav').getByRole('button').filter({ has: page.locator('svg') }).first().click()
    await page.getByRole('link', { name: 'Proceed to Checkout' }).click()
    await expect(page).toHaveURL('/checkout')
  })
})
