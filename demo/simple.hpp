#pragma once

/// Some library

/**
 * function which does stuff
 */
void do_stuff(int n = 34);

/**
 Some macro which has args
*/
#define MACRO(a, b) (a) + (b)

void dont_do_stuff(const char* foo = "///<"); ///< hehe

/// doc func
void doc_func(const char* hehe = "{")
{ code(); }
