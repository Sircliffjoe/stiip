class Badge::Component < ViewComponent::Base
  def initialize(text:, color: :navy)
    @text = text
    @color = color
  end

  def color_classes
    case @color.to_sym
    when :navy then "bg-navy-100 border border-navy-300 text-navy-700"
    when :green then "bg-green-100 border border-green-300 text-green-700"
    when :red then "bg-red-100 border border-red-300 text-red-700"
    else "bg-gray-100 border border-gray-300 text-gray-700"
    end
  end
end
