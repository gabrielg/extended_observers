require 'test_helper'
require 'ruby-debug'

# Don't really need a DB connection for these tests
class ActiveRecord::Base
  def self.columns; []; end
end

class Topic < ActiveRecord::Base; end
class Developer < ActiveRecord::Base; end
class Reply < ActiveRecord::Base; end

class ActivityObserver < ActiveRecord::Observer
  observe :topic, :after => [:create, :destroy], :before => :update
  observe :topic, :developer, :on => [:before_destroy, 'before_save']
  observe :reply
end

class ExtendedObserversTest < ActiveRecord::TestCase
  
  def setup
    @observer = ActivityObserver.instance
  end
  
  context "observing a topic" do
  
    topic = Topic.new
    
    should "observe after_create on Topic" do
      @observer.expects(:after_create).with(topic)
      topic.send(:notify, :after_create)
    end

    should "observe after_destroy on Topic" do
      @observer.expects(:after_destroy).with(topic)
      topic.send(:notify, :after_destroy)
    end
    
    should "observe before_update on Topic" do
      @observer.expects(:before_update).with(topic)
      topic.send(:notify, :before_update)
    end
    
    should "observe before_destroy on Topic" do 
      @observer.expects(:before_destroy).with(topic)
      topic.send(:notify, :before_destroy)
    end
  
    should "observe before_save on Topic" do
      @observer.expects(:before_save).with(topic)
      topic.send(:notify, :before_save)
    end
  
    should "ignore after_save and after_validation on topic" do
      @observer.expects(:after_save).with(topic).never
      @observer.expects(:after_validation).with(topic).never
      topic.send(:notify, :after_save)
      topic.send(:notify, :after_validation)
    end
    
  end # observing a topic

  context "observing a developer" do
    developer = Developer.new
    
    should "observe before_destroy on Developer" do
      @observer.expects(:before_destroy).with(developer)
      developer.send(:notify, :before_destroy)
    end
  
    should "observe before_save on Developer" do
      @observer.expects(:before_save).with(developer)
      developer.send(:notify, :before_save)
    end
    
  end
  
  should "observe all callbacks on Reply" do
    reply = Reply.new
    ActiveRecord::Callbacks::CALLBACKS.each do |callback|
      @observer.expects(callback).with(reply)
      reply.send(:notify, callback)
    end
  end
  
end
