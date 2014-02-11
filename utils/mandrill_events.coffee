module.exports =

  getRecipients: (to) ->
    recipients = []

    for recipient in to
      recipient = recipient[0]
      if /<[^>]*>/.test recipient
        recipient = recipient.match(/<([^>]*)>/)[1]
      unless /[^@]@shibe.io/.test recipient
        recipients.push recipient

    recipients

  getValue: (subject) ->
    parseFloat subject

  process: (event_json) ->
    m_events = JSON.parse event_json

    transactions = []

    m_events.forEach (m_event) ->

      amount = module.exports.getValue m_event.msg.subject

      for recipient in module.exports.getRecipients m_event.msg.to
        if amount > 0 and recipient
          transactions.push
            amount: amount
            to: recipient
            from: m_event.msg.from_email

    transactions
