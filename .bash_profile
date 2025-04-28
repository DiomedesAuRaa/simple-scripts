
alias l='ls -CF'
alias la='ls -A'
alias ll='ls -alF'
alias ls='ls --color=auto'
alias sl="ls"
alias python="python3"

#Kubernetes
alias k="kubectl"
alias kx="kubectx"
alias kns="kubens"

#Terraform
alias tf='terraform'
alias tfinit='terraform init --upgrade'

# github
alias gcam="git commit -m"

# pyenv setup
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
