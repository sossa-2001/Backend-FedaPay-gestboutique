require('dotenv').config();
const express = require('express');
const axios = require('axios');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const FEDAPAY_SECRET_KEY = process.env.FEDAPAY_SECRET_KEY;
const FEDAPAY_ENV = process.env.FEDAPAY_ENVIRONMENT || 'live';
const FEDAPAY_BASE = FEDAPAY_ENV === 'sandbox'
  ? 'https://sandbox-api.fedapay.com/v1'
  : 'https://api.fedapay.com/v1';
const CALLBACK_URL = process.env.CALLBACK_URL || 'https://backend-fedapay-gestboutique.onrender.com/payment-redirect';
const DEEP_LINK = process.env.DEEP_LINK || 'gestboutique://payment/status';

const FEDAPAY_HEADERS = {
  'Authorization': `Bearer ${FEDAPAY_SECRET_KEY}`,
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};

// ---------- Helpers ----------

function parsePhone(phone) {
  const digits = phone.replace(/[^0-9]/g, '');
  const codes = {
    '229': 'BJ', '237': 'CM', '225': 'CI', '221': 'SN',
    '223': 'ML', '226': 'BF', '228': 'TG', '227': 'NE',
    '224': 'GN', '233': 'GH', '234': 'NG',
  };
  for (const [code, country] of Object.entries(codes)) {
    if (digits.startsWith(code)) {
      return { country, number: digits };
    }
  }
  return { country: 'BJ', number: digits };
}

function splitName(fullName) {
  const parts = fullName.trim().split(/\s+/);
  return {
    firstname: parts.slice(0, -1).join(' ') || parts[0],
    lastname: parts.length > 1 ? parts[parts.length - 1] : parts[0],
  };
}

// ---------- FedaPay API calls ----------

async function createFedaPayTransaction({ description, amount, customer }) {
  const payload = {
    description,
    amount,
    currency: { iso: 'XOF' },
    callback_url: CALLBACK_URL,
    customer,
  };
  const res = await axios.post(`${FEDAPAY_BASE}/transactions`, payload, { headers: FEDAPAY_HEADERS });
  return res.data;
}

async function getFedaPayTransaction(transactionId) {
  const res = await axios.get(`${FEDAPAY_BASE}/transactions/${transactionId}`, { headers: FEDAPAY_HEADERS });
  return res.data;
}

// ---------- Routes ----------

app.get('/', (_req, res) => res.json({ status: 'ok', service: 'Gest-Boutique FedaPay' }));
app.get('/health', (_req, res) => res.json({ status: 'ok' }));

// Créer un paiement FedaPay
app.post('/create-payment', async (req, res) => {
  try {
    const { amount, description, customer_name, customer_phone, customer_email } = req.body;

    if (!amount || !description || !customer_name || !customer_phone) {
      return res.status(400).json({ success: false, message: 'Champs requis manquants' });
    }

    const phoneInfo = parsePhone(customer_phone);
    const nameParts = splitName(customer_name);

    const customer = {
      firstname: nameParts.firstname,
      lastname: nameParts.lastname,
      phone_number: { number: phoneInfo.number, country: phoneInfo.country },
    };
    if (customer_email) {
      customer.email = customer_email;
    }

    const result = await createFedaPayTransaction({
      description,
      amount: Math.round(amount),
      customer,
    });

    console.log('FedaPay response:', JSON.stringify(result, null, 2));

    const txnWrapper = result?.['v1/transaction'];
    const transaction = txnWrapper || result?.v1?.transaction;
    if (!transaction) {
      const errMsg = result?.['v1/message']
        || result?.v1?.message
        || result?.message
        || JSON.stringify(result?.errors || result)
        || 'Réponse FedaPay invalide';
      return res.status(500).json({ success: false, message: errMsg });
    }

    const paymentUrl = transaction.payment_url?.url
      || transaction.payment_url
      || null;

    return res.json({
      success: true,
      transaction_id: transaction.id,
      reference: transaction.reference,
      payment_url: paymentUrl,
    });
  } catch (err) {
    console.error('Erreur /create-payment:', err?.response?.data || err.message);
    const msg = err?.response?.data?.v1?.transaction?.message
      || err?.response?.data?.message
      || 'Erreur lors de la création du paiement';
    return res.status(500).json({ success: false, message: msg });
  }
});

// Vérifier le statut d'un paiement
app.get('/verify-payment/:id', async (req, res) => {
  try {
    const result = await getFedaPayTransaction(req.params.id);
    const transaction = result?.v1?.transaction;

    if (!transaction) {
      return res.status(404).json({ success: false, message: 'Transaction introuvable' });
    }

    return res.json({
      success: true,
      status: transaction.status,
      transaction: {
        id: transaction.id,
        status: transaction.status,
        reference: transaction.reference,
        amount: transaction.amount,
      },
    });
  } catch (err) {
    console.error('Erreur /verify-payment:', err?.response?.data || err.message);
    return res.status(500).json({ success: false, message: 'Erreur de vérification' });
  }
});

// Redirection après paiement FedaPay (callback)
app.get('/payment-redirect', (req, res) => {
  const { status, id } = req.query;
  const redirectUrl = `${DEEP_LINK}?transaction_id=${id || ''}&status=${status || 'unknown'}`;
  res.redirect(redirectUrl);
});

// Webhook FedaPay
app.post('/fedapay-webhook', (req, res) => {
  const event = req.body;
  console.log('Webhook reçu:', JSON.stringify(event, null, 2));

  const type = event?.v1?.type || event?.type;
  const transaction = event?.v1?.transaction || event?.transaction;

  if (type && transaction) {
    switch (type) {
      case 'transaction.approved':
        console.log(`Transaction approuvée: ${transaction.id} - ${transaction.reference}`);
        break;
      case 'transaction.declined':
        console.log(`Transaction refusée: ${transaction.id}`);
        break;
      case 'transaction.canceled':
        console.log(`Transaction annulée: ${transaction.id}`);
        break;
      default:
        console.log(`Événement non géré: ${type}`);
    }
  }

  res.status(200).json({ received: true });
});

app.listen(PORT, () => {
  console.log(`Gest-Boutique backend démarré sur le port ${PORT}`);
  console.log(`Environnement FedaPay: ${FEDAPAY_ENV}`);
  console.log(`Base URL FedaPay: ${FEDAPAY_BASE}`);
});
