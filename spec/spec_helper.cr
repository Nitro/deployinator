require "spec2"
require "../src/deployinator"

Spec2.doc

macro mock(methods)
  {% for key, value in methods %}
    def {{ key }}(*args)
      {{ value }}
    end
  {% end %}
end

