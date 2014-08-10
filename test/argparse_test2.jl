# test 2: version information, default values, flags,
#         options with types, optional arguments, variable
#         number of arguments;
#         function version of add_arg_table

using OptionsMod

function ap_settings2()

    s = ArgParseSettings(description = "Test 2 for ArgParse.jl",
                         epilog = "Have fun!",
                         version = "Version 1.0",
                         add_version = true,
                         exc_handler = ArgParse.debug_handler)

    @add_arg_table s begin
        "--opt1"
            nargs = '?'              # '?' means optional argument
            arg_type = Int           # only Int arguments allowed
            default = 0              # this is used when the option is not passed
            constant = 1             # this is used if --opt1 is paseed with no argument
            help = "an option"
        "--flag", "-f"
            action = :store_true   # this makes it a flag
            help = "a flag"
        "--karma", "-k"
            action = :count_invocations  # increase a counter each time the option is given
            help = "increase karma"
        "arg1"
            nargs = 2                        # eats up two arguments; puts the result in a Vector
            help = "first argument, two " *
                   "entries at once"
            required = true
        "arg2"
            nargs = '*'                            # eats up as many arguments as possible before an option
            default = {"no_arg_given"}             # since the result will be a Vector{Any}, the default must
                                                   # also be (or it can be [] or nothing)
            help = "second argument, eats up " *
                   "as many items as possible " *
                   "before an option"
    end

    return s
end

function ap_settings2b()

    s = ArgParseSettings(description = "Test 2 for ArgParse.jl",
                         epilog = "Have fun!",
                         version = "Version 1.0",
                         add_version = true,
                         exc_handler = ArgParse.debug_handler)

    add_arg_table(s,
        "--opt1", @options(
            nargs = '?',             # '?' means optional argument
            arg_type = Int,          # only Int arguments allowed
            default = 0,             # this is used when the option is not passed
            constant = 1,            # this is used if --opt1 is paseed with no argument
            help = "an option"),
        ["--flag", "-f"], @options(
            action = :store_true,  # this makes it a flag
            help = "a flag"),
        ["--karma", "-k"], @options(
            action = :count_invocations, # increase a counter each time the option is given
            help = "increase karma"),
        "arg1", @options(
            nargs = 2,                       # eats up two arguments; puts the result in a Vector
            help = "first argument, two " *
                   "entries at once",
            required = true),
        "arg2", @options(
            nargs = '*',                           # eats up as many arguments as possible before an option
            default = {"no_arg_given"},            # since the result will be a Vector{Any}, the default must
                                                   # also be (or it can be [] or nothing)
            help = "second argument, eats up " *
                   "as many items as possible " *
                   "before an option")
    )

    return s
end

for s = [ap_settings2(), ap_settings2b()]
    ap_test2(args) = parse_args(args, s)

    @test stringhelp(s) == """
        usage: $(basename(Base.source_path())) [--opt1 [OPT1]] [-f] [-k] arg1 arg1 [arg2...]

        Test 2 for ArgParse.jl

        positional arguments:
          arg1           first argument, two entries at once
          arg2           second argument, eats up as many items as possible
                         before an option (default: {"no_arg_given"})

        optional arguments:
          --opt1 [OPT1]  an option (type: Int64, default: 0, without arg: 1)
          -f, --flag     a flag
          -k, --karma    increase karma

        Have fun!

        """

    @test stringversion(s) == "Version 1.0\n"

    @ap_test_throws ap_test2([])
    @test ap_test2(["X", "Y"]) == (String=>Any)["opt1"=>0, "flag"=>false, "karma"=>0, "arg1"=>{"X", "Y"}, "arg2"=>{"no_arg_given"}]
    @test ap_test2(["X", "Y", "-k", "-f", "Z", "--karma", "--opt"]) == (String=>Any)["opt1"=>1, "flag"=>true, "karma"=>2, "arg1"=>{"X", "Y"}, "arg2"=>{"Z"}]
    @test ap_test2(["--opt", "-3", "X", "Y", "-k", "-f", "Z", "--karma"]) == (String=>Any)["opt1"=>-3, "flag"=>true, "karma"=>2, "arg1"=>{"X", "Y"}, "arg2"=>{"Z"}]
    @ap_test_throws ap_test2(["--opt", "1e-2", "X", "Y"])

    @test_throws_02 ErrorException @add_arg_table(s, "required_arg_after_optional_args", required=true)
    #wrong default
    @test_throws_02 ErrorException @add_arg_table(s, "--opt", arg_type = Int, default = 1.5)
    #wrong range tester
    @test_throws_02 ErrorException @add_arg_table(s, "--opt", arg_type = Int, range_tester=x->string(x), default = 1)
    @test_throws_02 ErrorException @add_arg_table(s, "--opt", arg_type = Int, range_tester=x->sqrt(x)<1, default = -1)
end
