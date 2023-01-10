str = <<RAW
#include <hello>

// func
template <typename T>
void foo(T* t = "jes\n");

int main() { xxx }
RAW

str.each_line.with_index do |l, i|
    puts "#{i}: #{l.chomp}"
end
