module Theo
  class Railtie < ::Rails::Railtie
    initializer 'initialize theo template handler' do
      ActiveSupport.on_load(:action_view) do
        ::ActionView::Template.register_template_handler :theo, :'erb.theo', Theo.new
      end
    end
  end
end
