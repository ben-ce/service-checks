if [[ $1 = IK ]]; then
	echo "Setting HTTP proxy"
	export http_proxy="172.30.5.21:3128"
	export https_proxy=$http_proxy
	export no_proxy="localhost"
	echo "HTTP proxy set"
fi

if [[ $1 = MW ]]; then
	echo "Unset HTTP proxy"
	unset http_proxy
	unset https_proxy
fi
