class Badge::Component < ViewComponent::Base
  def initialize(text:, color: :emerald)
    @text = text
    @color = color
  end

  def color_classes
    case @color.to_sym
    when :emerald then "bg-emerald-500/10 border border-emerald-500/20 text-emerald-400"
    when :blue then "bg-blue-500/10 border border-blue-500/20 text-blue-400"
    when :purple then "bg-purple-500/10 border border-purple-500/20 text-purple-400"
    when :red then "bg-red-500/10 border border-red-500/20 text-red-400"
    else "bg-gray-800 border border-gray-700 text-gray-300"
    end
  end
end
