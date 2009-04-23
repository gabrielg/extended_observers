require 'active_support'
require 'active_record'
require 'active_record/observer'

# Monkey patch until http://rails.lighthouseapp.com/projects/8994-ruby-on-rails/tickets/1639
# gets accepted.
module ActiveRecord 
  class Observer
    write_inheritable_hash :observable_updates, {}
    class << self
      
      # Attaches the observer to the supplied model classes.
      def observe(*models)
        options = models.extract_options!
        set_watch_options(models, options)
        models = constantize_models(models)
        already_observed = read_inheritable_attribute(:observed_classes)
        write_inheritable_attribute(:observed_classes, Set.new(Array(already_observed)) + Set.new(models))
      end

    private

      def set_watch_options(models, options)
        on_methods = options.inject([]) do |methods,(key,val)|
          if [:before, :after].include?(key)
            methods.concat(Array(val).map {|v| :"#{key}_#{v}"})
          elsif key == :on
            methods.concat(Array(val).map(&:to_sym))
          end
          methods
        end
        constantize_models(models).each do |model|
          existing = (obs = read_inheritable_attribute(:observable_updates)) ? obs[model] : []
          write_inheritable_hash(:observable_updates, model => Array(existing) + on_methods)
        end
      end
      
      def constantize_models(models)
        models.flatten.collect { |model| model.is_a?(Symbol) ? model.to_s.camelize.constantize : model }
      end
      
    end # << self

    # Send observed_method(object) if the method exists.
    def update(observed_method, object) #:nodoc:
      send(observed_method, object) if listening_for?(object, observed_method)
    end
    
    def observed_classes
      self.class.read_inheritable_attribute(:observed_classes) || Set.new([self.class.observed_class].compact.flatten)
    end

  protected

    def listening_for?(object, observed_method)
      respond_to?(observed_method) && watching?(object, observed_method)
    end

    def watching?(object, observed_method)
      observed = self.class.read_inheritable_attribute(:observable_updates)
      observed[object.class].blank? || observed[object.class].include?(observed_method.to_sym)
    end
      
  end   # Observer
end     # ActiveRecord
