function venv-create -d "Create a virtual environment in a centralised location"
    argparse 'h/help' 'p/python=' -- $argv 2>/dev/null
    argparse -N 1 -X 1 -- $argv 2>/dev/null or return 0

    if test $_flag_help
        echo "Usage: venv-create --python PYTHON-VERSION <venv_name>"
        return 0
    end

    if test (count $argv) -ne 1
        echo "Usage: venv-create --python PYTHON-VERSION <venv_name>"
        return 1
    end

    set -l venv_name $argv[1]
    set -q VENV_ROOT; and set -l venv_root $VENV_ROOT; or set -l venv_root $HOME/.local/share/virtualenv

    mkdir -p $venv_root

    pushd $venv_root > /dev/null

    if test $_flag_python
        uv venv --python $_flag_python $venv_name
    else
        uv venv $venv_name
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

    set -gx VIRTUAL_ENV $venv_root/$venv_name
    fish_add_path --path $venv_root/$venv_name/bin
end

function venv-reset -d "Resets the default virtual environment"
    if type -q deactivate
        deactivate > /dev/null
    end

    if test -n $VIRTUAL_ENV
        if set -l index (contains -i $VIRTUAL_ENV/bin $PATH)
            set -e PATH[$index]
        end
    end

    set -q DEFAULT_VENV; or set DEFAULT_VENV "gallegoj"
    venv-activate $DEFAULT_VENV
end

function venv-uv -d "Create a virtual environment with the given name and add mise-en-place configuration"
    argparse 'p/python=' -- $argv 2>/dev/null
    argparse -N 0 -X 1 -- $argv 2>/dev/null or return 0

    if test (count $argv) -ge 2
        echo "Usage: venv-uv --python PYTHON-VERSION [<venv_name>]"
        return 1
    end

    set venv_name $argv[1]
    if test -z $venv_name
        set venv_name ".venv"
    end

    if test $_flag_python
        uv venv --python $_flag_python $venv_name
    else
        uv venv $venv_name
    end

    echo "layout_uv" > .envrc
    direnv allow
end

function venv-list -d "List virtual environments in the centralised location"
    set -q VENV_ROOT; and set -l venv_root $VENV_ROOT; or set -l venv_root $HOME/.local/share/virtualenv
    find $venv_root -mindepth 1 -maxdepth 1 -type d -printf "%f\n"
end
