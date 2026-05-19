class Constants {
  // Device Status
  static const String deviceStatusPending = 'pending';
  static const String deviceStatusActive = 'active';
  static const String deviceStatusInactive = 'inactive';

  // Transaction Status
  static const String paymentStatusPaid = 'paid';
  static const String paymentStatusPartial = 'partial';
  static const String paymentStatusRefund = 'refund';

  // Payment Methods
  static const String paymentMethodCash = 'cash';
  static const String paymentMethodCard = 'card';
  static const String paymentMethodEwallet = 'ewallet';

  // Sync Status
  static const String syncStatusPending = 'pending';
  static const String syncStatusSuccess = 'success';
  static const String syncStatusFailed = 'failed';

  // Sync Actions
  static const String syncActionCreate = 'create';
  static const String syncActionUpdate = 'update';
  static const String syncActionDelete = 'delete';

  // Entity Types
  static const String entityTypeTransaction = 'transaction';
  static const String entityTypeTransactionWithInvoice = 'transaction_with_invoice';
  static const String entityTypeProduct = 'product';
  static const String entityTypeCustomer = 'customer';
  static const String entityTypeAppointment = 'appointment';
  static const String entityTypeInventory = 'inventory';

  // Inventory Transaction Types
  static const String inventoryTypePurchase = 'purchase';
  static const String inventoryTypeSale = 'sale';
  static const String inventoryTypeAdjustment = 'adjustment';
  static const String inventoryTypeStocktake = 'stocktake';

  // Appointment Status
  static const String appointmentStatusPending = 'pending';
  static const String appointmentStatusConfirmed = 'confirmed';
  static const String appointmentStatusCompleted = 'completed';
  static const String appointmentStatusCancelled = 'cancelled';

  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleCashier = 'cashier';
  static const String roleInventoryManager = 'inventory_manager';
  static const String roleServiceStaff = 'service_staff';

  // Tax Types
  static const String taxTypeStandard = 'standard';
  static const String taxTypeZeroRated = 'zero_rated';
  static const String taxTypeExempt = 'exempt';

  // Business Types
  static const String businessTypeRetail = 'retail';
  static const String businessTypeService = 'service';
  static const String businessTypeBoth = 'both';

  // Storage Keys
  static const String keyDeviceId = 'device_id';
  static const String keyDeviceToken = 'device_token';
  static const String keyTenantId = 'tenant_id';
  static const String keyUserId = 'user_id';
  static const String keyLastSyncTime = 'last_sync_time';
  static const String keyPosSettings = 'pos_settings';

  // Date Formats
  static const String dateFormatDisplay = 'dd/MM/yyyy';
  static const String dateFormatApi = 'yyyy-MM-dd';
  static const String dateTimeFormatDisplay = 'dd/MM/yyyy HH:mm';
  static const String dateTimeFormatApi = 'yyyy-MM-ddTHH:mm:ss';
  static const String timeFormat = 'HH:mm';

  // Validation
  static const int minPinLength = 4;
  static const int maxPinLength = 6;
  static const int pairingCodeLength = 6;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}
