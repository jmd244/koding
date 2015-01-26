package main

import (
	"encoding/json"
	"net/http"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
)

type paypalActionType func(*webhookmodels.PaypalGenericWebhook, *Controller) error

var paypalActions = map[string]paypalActionType{
	"recurring_payment_profile_created": paypalSubscriptionCreated,
	"recurring_payment_profile_cancel":  paypalSubscriptionDeleted,
	"recurring_payment_failed":          paypalPaymentFailed,
	"recurring_payment":                 paypalPaymentSucceeded,
	"recurring_payment_skipped":         paypalPaymentFailed,
}

type paypalMux struct {
	Controller *Controller
}

func (p *paypalMux) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	var req *webhookmodels.PaypalGenericWebhook

	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		Log.Error("Error marshalling Paypal webhook : %v", err)
		return
	}

	action, ok := paypalActions[req.TransactionType]
	if !ok {
		Log.Error("Paypal webhook: %s, %s not implemented",
			req.Status, req.TransactionType)

		return
	}

	err = action(req, p.Controller)
	if err != nil {
		Log.Error("Paypal webhook: %s action failed: %s", req.PayerId, err)
		return
	}
}
