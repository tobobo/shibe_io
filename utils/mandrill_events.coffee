module.exports =

  getRecipients: (to) ->
    recipients = []

    for recipient in to
      console.log recipient
      recipient = recipient[0]
      console.log recipient
      if /<[^>]*>/.test recipient
        recipient = recipient.match(/<([^>]*)>/)[1]
      console.log recipient
      unless /[^@]@shibe.io/.test recipient
        recipients.push recipient
        
    console.log 'recipients', recipients
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
