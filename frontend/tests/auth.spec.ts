import { test, expect } from '@playwright/test'

test.describe('Authentication', () => {
  test('should open login modal', async ({ page }) => {
    await page.goto('/')
    await page.locator('nav').getByRole('button', { name: 'Login' }).click()
    await expect(page.getByRole('heading', { name: 'Login' })).toBeVisible()
  })

  test('should switch to register mode', async ({ page }) => {
    await page.goto('/')
    await page.locator('nav').getByRole('button', { name: 'Login' }).click()
    await page.getByRole('button', { name: 'Register' }).click()
    await expect(page.getByRole('heading', { name: 'Register' })).toBeVisible()
  })
})
