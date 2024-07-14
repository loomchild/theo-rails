module Theo
  module Rails
    module Helpers
      def provide(**args)
        @theo_context ||= {}
        @theo_context.merge!(args)

        yield

        @theo_context.except!(args.keys)
      end

      def inject(key)
        @theo_context&.[](key)
      end
    end
  end
end
