import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'settings': 'Settings',
      'general': 'General',
      'company_name': 'Company Name',
      'language': 'Language',
      'currency': 'Currency',
      'date_format': 'Date Format',
      'configuration': 'Configuration',
      'backup': 'Backup',
      'account': 'Account',
      'subscription': 'Subscription',
      'notifications': 'Notifications',
      'about': 'About',
      'version': 'Version',
      'status': 'Status',
      'last_backup': 'Last Backup',
      'backup_now': 'Backup Now',
      'manage_subscription': 'Manage Subscription',
      'logout': 'Log Out',
      'connected_as': 'Connected as',
      'save': 'Save',
      'cancel': 'Cancel',
      'enter_company_name': 'Enter company name',
      'low_stock_alert': 'Low Stock Alert',
      'low_stock_desc': 'Receive notification when stock is low',
      'order_reminders': 'Order Reminders',
      'order_reminders_desc': 'Notifications for pending orders',
      'store_connected': 'Store Connected',
      'not_configured': 'Not Configured',
      'enable_cloud_backup': 'Enable cloud backup',
      'manage_config': 'Manage Configuration',
      'configure_store': 'Configure Store',
      'plan_label': 'Current Plan',
      'monthly': 'Monthly',
      'annual': 'Annual',
      '_2months_off': '-2 months',
      'active_subscription': 'Active Subscription',
      'expires_on': 'Expires on',
      'expired_banner': 'Your subscription has expired. Choose a plan to continue.',
      'current_plan': 'Current Plan',
      'choose': 'Choose',
      'subscription_details': 'Subscription Details',
      'plan': 'Plan',
      'start': 'Start',
      'expiry': 'Expiry',
      'last_payment': 'Last Payment',
      'billing': 'Billing',
      'annual_label': 'Annual',
      'monthly_label': 'Monthly',
      'fee': 'Fee',
      'contact_support': 'Contact Support',
      'payment_title': 'FedaPay Payment',
      'full_name': 'Full Name *',
      'country': 'Country *',
      'phone': 'Phone *',
      'email_optional': 'Email (optional)',
      'required': 'Required',
      'pay': 'Pay',
      'total': 'Total',
      'phone_too_short': 'Number too short',
      'phone_too_long': 'Too long',
      'per_year': '/year',
      'per_month': '/month',
      'dashboard': 'Dashboard',
      'products': 'Products',
      'clients': 'Clients',
      'reports': 'Reports',
      'stock': 'Stock',
      'sell': 'Sell',
      'invoices': 'Invoices',
      'stock_movements': 'Stock Movements',
      'pos': 'Point of Sale',
      'expires_in_days': 'Subscription expires in {days} day(s)',
      'expires_in_min': 'Subscription expires in {min} min',
      'expires_soon': 'Subscription expires soon',
      'renew': 'Renew',
      'login': 'Sign In',
      'new_connection': 'New Connection',
      'continue_guest': 'Continue',
      'password': 'Password',
      'forgot_password': 'Forgot Password?',
      'back_btn': 'Back',
      'recover_password': 'Password Recovery',
      'recover_desc': 'Enter the Gmail email registered during setup.',
      'email': 'Email',
      'send': 'Send',
      'no_internet': 'No Internet Connection',
      'no_internet_desc': 'Connecting to an existing account requires an internet connection.',
      'fill_all_fields': 'Fill all fields',
      'ok': 'OK',
      'professional_mgmt': 'Professional Store Management',
      'login_hint': 'Login',
    },
    'fr': {
      'settings': 'Paramètres',
      'general': 'Général',
      'company_name': 'Nom de l\'entreprise',
      'language': 'Langue',
      'currency': 'Devise',
      'date_format': 'Format de date',
      'configuration': 'Configuration',
      'backup': 'Sauvegarde',
      'account': 'Compte',
      'subscription': 'Abonnement',
      'notifications': 'Notifications',
      'about': 'À propos',
      'version': 'Version',
      'status': 'Statut',
      'last_backup': 'Dernière sauvegarde',
      'backup_now': 'Sauvegarder maintenant',
      'manage_subscription': 'Gérer l\'abonnement',
      'logout': 'Se déconnecter',
      'connected_as': 'Connecté en tant que',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'enter_company_name': 'Entrez le nom de l\'entreprise',
      'low_stock_alert': 'Alerte stock faible',
      'low_stock_desc': 'Recevoir une notification quand le stock est bas',
      'order_reminders': 'Rappels de commandes',
      'order_reminders_desc': 'Notifications pour les commandes en attente',
      'store_connected': 'Boutique connectée',
      'not_configured': 'Non configurée',
      'enable_cloud_backup': 'Activez la sauvegarde cloud',
      'manage_config': 'Gérer la configuration',
      'configure_store': 'Configurer la boutique',
      'plan_label': 'Plan actuel',
      'monthly': 'Mensuel',
      'annual': 'Annuel',
      '_2months_off': '-2 mois',
      'active_subscription': 'Abonnement actif',
      'expires_on': 'Expire le',
      'expired_banner': 'Votre abonnement a expiré. Choisissez un plan pour continuer.',
      'current_plan': 'Plan actuel',
      'choose': 'Choisir',
      'subscription_details': 'Détails de l\'abonnement',
      'plan': 'Plan',
      'start': 'Début',
      'expiry': 'Expiration',
      'last_payment': 'Dernier paiement',
      'billing': 'Facturation',
      'annual_label': 'Annuelle',
      'monthly_label': 'Mensuelle',
      'fee': 'Frais',
      'contact_support': 'Contact support',
      'payment_title': 'Paiement FedaPay',
      'full_name': 'Nom complet *',
      'country': 'Pays *',
      'phone': 'Téléphone *',
      'email_optional': 'Email (optionnel)',
      'required': 'Requis',
      'pay': 'Payer',
      'total': 'Total',
      'phone_too_short': 'Numéro trop court',
      'phone_too_long': 'Trop long',
      'per_year': '/an',
      'per_month': '/mois',
      'dashboard': 'Tableau de bord',
      'products': 'Produits',
      'clients': 'Clients',
      'reports': 'Rapports',
      'stock': 'Stock',
      'sell': 'Vendre',
      'invoices': 'Factures',
      'stock_movements': 'Mouvements de stock',
      'pos': 'Point de vente',
      'expires_in_days': 'Abonnement expire dans {days} jour(s)',
      'expires_in_min': 'Abonnement expire dans {min} min',
      'expires_soon': 'Abonnement expire bientôt',
      'renew': 'Renouveler',
      'login': 'Connexion',
      'new_connection': 'Nouvelle connexion',
      'continue_guest': 'Continuer',
      'password': 'Mot de passe',
      'forgot_password': 'Mot de passe oublié ?',
      'back_btn': 'Retour',
      'recover_password': 'Récupération de mot de passe',
      'recover_desc': 'Entrez l\'email Gmail enregistré lors de la configuration.',
      'email': 'Email',
      'send': 'Envoyer',
      'no_internet': 'Aucune connexion internet',
      'no_internet_desc': 'La connexion à un compte existant nécessite une connexion internet.',
      'fill_all_fields': 'Remplissez tous les champs',
      'ok': 'OK',
      'professional_mgmt': 'Gestion professionnelle de boutique',
      'login_hint': 'Login',
    },
  };

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ?? AppLocalizations(const Locale('fr'));
  }

  String t(String key, {Map<String, String>? params}) {
    final langMap = _translations[locale.languageCode];
    var text = langMap?[key] ?? _translations['fr']?[key] ?? key;
    if (params != null) {
      params.forEach((k, v) {
        text = text.replaceAll('{$k}', v);
      });
    }
    return text;
  }

  String get languageCode => locale.languageCode;
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'fr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) => Future.value(AppLocalizations(locale));

  @override
  bool shouldReload(AppLocalizationsDelegate old) => true;
}

extension Trans on BuildContext {
  String tr(String key, {Map<String, String>? params}) =>
      AppLocalizations.of(this).t(key, params: params);
}

extension CurrencyFormatExt on BuildContext {
  String formatCurrency(num amount, {bool showSymbol = true}) {
    final locale = AppLocalizations.of(this).languageCode;
    final symbol = showSymbol ? 'FCFA ' : '';
    return '$symbol${NumberFormat('#,##0', locale).format(amount)}';
  }
}
