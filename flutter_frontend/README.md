# Godavari Ghaatu Flutter Frontend

This directory contains a Flutter client for the existing FastAPI backend in `backend/`.

## Current scope

- Customer storefront for products, variants, combo breakdowns, cart, orders, and UPI payment details
- Account login and registration against the FastAPI auth endpoints
- Admin control room with custom-painted hero panels for catalog and fulfilment workflows
- Product studio for create/edit, archive/restore, variant ladders, and combo composition management

## Important note

Flutter is not installed in this workspace, so this project was generated manually.
That means platform folders like `android/`, `ios/`, `web/`, `macos/`, `linux/`, and `windows/`
are not present yet.

After installing Flutter, generate them from inside this directory:

```bash
flutter create .
```

That will keep the `lib/` and `test/` code here and add the missing platform scaffolding.

## Run steps

1. Start the backend from `backend/`.
2. Install Flutter if it is not already available.
3. From this directory run:

```bash
flutter create .
flutter pub get
flutter test
flutter analyze
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

### Base URL guidance

- Android emulator: `http://10.0.2.2:8000`
- iOS simulator / desktop Flutter: `http://127.0.0.1:8000`
- Flutter web: `http://localhost:8000`
- Physical device: use your machine's LAN IP

If `API_BASE_URL` is omitted, the app chooses a sensible local default based on platform.

## Backend endpoints used

### Customer flows

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `GET /api/v1/users/me`
- `GET /api/v1/products`
- `GET /api/v1/products/{id}`
- `GET /api/v1/products/{id}/variants`
- `GET /api/v1/products/{id}/combo-items`
- `GET /api/v1/cart`
- `POST /api/v1/cart/items`
- `PUT /api/v1/cart/items/{id}`
- `DELETE /api/v1/cart/items/{id}`
- `POST /api/v1/orders`
- `GET /api/v1/orders`
- `GET /api/v1/payments/upi/{order_id}`

### Admin flows

- `GET /api/v1/products?active_only=false`
- `POST /api/v1/products`
- `PUT /api/v1/products/{product_id}`
- `DELETE /api/v1/products/{product_id}`
- `POST /api/v1/products/{product_id}/variants`
- `PUT /api/v1/products/{product_id}/variants/{variant_id}`
- `DELETE /api/v1/products/{product_id}/variants/{variant_id}`
- `POST /api/v1/products/{product_id}/combo-items`
- `PUT /api/v1/products/{product_id}/combo-items/{item_id}`
- `DELETE /api/v1/products/{product_id}/combo-items/{item_id}`
- `POST /api/v1/payments/verify/{order_id}`
- `PATCH /api/v1/orders/{order_id}/pack`
- `PATCH /api/v1/orders/{order_id}/ship`
- `PATCH /api/v1/orders/{order_id}/deliver`

## Validation status

The Flutter SDK and standalone Dart SDK are not installed in this environment, so `flutter create .`,
`flutter pub get`, `flutter test`, `flutter analyze`, `flutter run`, and `dart --version` could not be executed here.
