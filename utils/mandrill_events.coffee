module.exports =

  getRecipients: (to) ->
    recipients = []

    for recipient in to
      address = recipient.match(/<([^>]*)>/)[1]
      unless /[^@]@shibe.io/.test address
        recipients.push address

    recipients

  getValue: (subject) ->
    parseFloat subject

  process: (event_json) ->
    m_events = JSON.parse event_json

    transactions = []

    m_events.forEach (m_event) ->

      for recipient in module.exports.getRecipients m_event.msg.to
        transactions.push
          amount: module.exports.getValue m_event.msg.subject
          to: recipient
          from: m_event.msg.from_email

    transactions
