# == Schema Information
#
# Table name: messages
#
#  id              :integer          not null, primary key
#  sender_id       :string(255)
#  content         :text(65535)
#  created_at      :datetime
#  updated_at      :datetime
#  conversation_id :integer
#
# Indexes
#
#  index_messages_on_conversation_id  (conversation_id)
#

class Message < ApplicationRecord

  after_save :update_conversation_read_status

  belongs_to :sender, :class_name => "Person"
  belongs_to :conversation

  scope :latest, -> { order(created_at: :desc) }

  validates_presence_of :sender_id
  validates_presence_of :content

  def update_conversation_read_status
    conversation.update_attribute(:last_message_at, created_at)
    conversation.participations.each do |p|
      last_at = p.person.eql?(sender) ? :last_sent_at : :last_received_at
      p.update({ :is_read => p.person.eql?(sender), last_at => created_at})
    end
  end

  # Send email notification to message receivers and returns the receivers
  def send_email_to_participants(community)
    conversation.recipients(sender).each do |recipient|
      if recipient.should_receive?("email_about_new_messages") || recipient.guest?
        MailCarrier.deliver_now(PersonMailer.new_message_notification(self, community))
      end
    end
  end
end
