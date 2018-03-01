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

void dont_do_stuff(const char* foo = "//<") //< hehe

/// Documented class
/// Does something
class lib_class {
public:
    /// Constructor
    lib_class();
    virtual ~lib_class();

    /// Template member func
    /// uses `other` to do stuff
    template <typename T>
    void t_member();

    /**
     * Cool inline function
     */
    int inline_func() const {
        // not a doc
        return m_var;
    }

    /// @ignore

    /// This is not a doc
    void non_documented()

    /// @endignore

protected:

    /**
      virtual member-function
     */
    virtual void vf() = 0; // no doc

private:
    // not a doc as well
    int m_var;

    /*********************
     * Totally not a doc *
     *********************/
    double m_var2;
};

/// Class which inherits from `lib_class`
class other : public lib_class {
    ////// no doc
    virtual void vf() override {
        do_stuff();
    }
};


/// Some caller function
/// Has variadic template arguments
template <typename T, typename... Args>
struct caller
{
    /*
    /// no doc
    /**
     no doc
    */
    T func(Args&&... args);
};
