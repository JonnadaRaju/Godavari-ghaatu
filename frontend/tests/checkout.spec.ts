import { test, expect } from '@playwright/test'

test.describe('Checkout', () => {
  test('should redirect empty cart to products', async ({ page }) => {
    await page.goto('/checkout')
    await expect(page.getByText('Your cart is empty')).toBeVisible()
  })

  test('should display checkout form', async ({ page }) => {
    await page.goto('/')
    await page.getByRole('link', { name: 'Mango Pickle' }).first().getByRole('button', { name: 'Add' }).click()
    await page.locator('nav').getByRole('button').filter({ has: page.locator('svg') }).first().click()
    await page.getByRole('link', { name: 'Proceed to Checkout' }).click()
    await expect(page.getByRole('heading', { name: 'Checkout' })).toBeVisible()
    await expect(page.getByText('Shipping Address')).toBeVisible()
    await expect(page.getByText('Order Summary')).toBeVisible()
  })

  test('should validate checkout form', async ({ page }) => {
    await page.goto('/')
    await page.getByRole('link', { name: 'Mango Pickle' }).first().getByRole('button', { name: 'Add' }).click()
    await page.locator('nav').getByRole('button').filter({ has: page.locator('svg') }).first().click()
    await page.getByRole('link', { name: 'Proceed to Checkout' }).click()
    await page.getByRole('button', { name: 'Place Order' }).click()
    await expect(page.getByText('Full Name')).toBeVisible()
  })
})
