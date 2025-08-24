function venv-create -d "Create a virtual environment in a centralised location"
    argparse 'h/help' 'p/python=' -- $argv 2>/dev/null
    argparse 'x/prompt=' -- $argv 2>/dev/null
    argparse -N 1 -X 1 -- $argv 2>/dev/null or return 0

    if test $_flag_help
        echo "Usage: venv-create --python PYTHON-VERSION --prompt PROMPT <venv_name>"
        return 0
    end

    if test (count $argv) -ne 1
        echo "Usage: venv-create --python PYTHON-VERSION --prompt PROMPT <venv_name>"
        return 1
    end

    set -l venv_name $argv[1]
    set -q VENV_ROOT; and set -l venv_root $VENV_ROOT; or set -l venv_root $HOME/.local/share/virtualenv

    mkdir -p $venv_root

    pushd $venv_root > /dev/null

    if test $_flag_prompt
        set -l venv_prompt $_flag_prompt
    else
        set -l venv_prompt (basename $PWD)
    end

    if test $_flag_python
        uv venv --python $_flag_python --prompt $venv_prompt $venv_name
    else
        uv venv --prompt $venv_prompt $venv_name
    end

    popd > /dev/null

    venv-activate $venv_name
end

function venv-activate -d "Activates a virtual environment from a centralised location"
    if test (count $argv) -ne 1
        echo "Usage: venv-activate <venv_name>"
        return 1
    end

    set -l venv_name $argv[1]
    set -q VENV_ROOT; and set -l venv_root $VENV_ROOT; or set -l venv_root $HOME/.local/share/virtualenv

    # set -gx VIRTUAL_ENV $venv_root/$venv_name
    # fish_add_path --path $venv_root/$venv_name/bin
    source $venv_root/$venv_name/bin/activate.fish
end

function venv-deactivate -d "Deactivates the current virtual environment"
    if type -q deactivate
        deactivate > /dev/null
    end

    if test -n $VIRTUAL_ENV
        if set -l index (contains -i $VIRTUAL_ENV/bin $PATH)
            set -e PATH[$index]
        end
        set -e VIRTUAL_ENV
    end
end

function venv-reset -d "Resets the default virtual environment"
    venv-deactivate

    set -q DEFAULT_VENV; or set DEFAULT_VENV "gallegoj"
    set -e VIRTUAL_ENV_PROMPT
    venv-activate $DEFAULT_VENV
end

function venv-uv -d "Create a virtual environment with the given name and add mise-en-place configuration"
    argparse 'p/python=' -- $argv 2>/dev/null
    argparse 'x/prompt=' -- $argv 2>/dev/null
    argparse -N 0 -X 1 -- $argv 2>/dev/null or return 0

    if test (count $argv) -ge 2
        echo "Usage: venv-uv --python PYTHON-VERSION --prompt PROMPT [<venv_name>]"
        return 1
    end

    set venv_name $argv[1]
    if test -z $venv_name
        set venv_name ".venv"
    end

    if test $_flag_prompt
        set venv_prompt $_flag_prompt
    else
        set venv_prompt (basename $PWD)
    end

    if test $_flag_python
        uv venv --python $_flag_python --prompt $venv_prompt $venv_name
    else
        uv venv --prompt $venv_prompt $venv_name
    end

    echo "layout_uv" > .envrc
    direnv allow
end

function venv-list -d "List virtual environments in the centralised location"
    set -q VENV_ROOT; and set -l venv_root $VENV_ROOT; or set -l venv_root $HOME/.local/share/virtualenv
    find $venv_root -mindepth 1 -maxdepth 1 -type d -printf "%f\n"
end

function venv-update-prompt -d "Updates the prompt in pyvenv.cfg"
    argparse 'd/dir=' -- $argv 2>/dev/null
    argparse -N 0 -X 1 -- $argv 2>/dev/null or return 0

    if test (count $argv) -ge 2
        echo "Usage: venv-update-prompt [-d/--dir VENV_DIR] [<prompt-name>]"
        return 1
    end

    set prompt $argv[1]
    if test -z $prompt
        set prompt (basename $PWD)
    end

    if test $_flag_dir
        set venv_dir $_flag_dir
    else
        if test $VIRTUAL_ENV
            set venv_dir $VIRTUAL_ENV
        else
            set venv_dir ".venv"
        end
    end

    set pyvenv_cfg "$venv_dir/pyvenv.cfg"
    if not test -e $pyvenv_cfg
        echo "No pyvenv.cfg found in $venv_dir/pyvenv.cfg"
        return 1
    end

    grep -E "prompt\s*=" $venv_dir/pyvenv.cfg > /dev/null
    if test $status -eq 0
        sed -i -E -r "s/^(prompt[[:space:]]?=[[:space:]]?).+/\1"$prompt"/g" $pyvenv_cfg
    else
        echo "prompt = $prompt" >> $pyvenv_cfg
    end
end
