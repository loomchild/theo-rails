module Theo
  module Rails
    class Railtie < ::Rails::Railtie
      initializer 'initialize theo' do
        ActiveSupport.on_load(:action_view) do
          ::ActionView::Template.register_template_handler :theo, Theo.new
          include ::Theo::Rails::Helpers
        end
      end
    end
  end
end
