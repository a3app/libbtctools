#ifndef BTCTOOLS_TCPCLIENT_ASIO_COMPAT
#define BTCTOOLS_TCPCLIENT_ASIO_COMPAT

#include <boost/version.hpp>
#if BOOST_VERSION >= 106600
#  include <boost/asio/io_context.hpp>
#else
#  include <boost/asio/io_service.hpp>
#endif
#include <boost/asio/steady_timer.hpp>

namespace btctools
{
	namespace tcpclient
	{
#if BOOST_VERSION >= 106600
		using IoService = boost::asio::io_context;
#else
		using IoService = boost::asio::io_service;
#endif
		using SteadyTimer = boost::asio::steady_timer;
	}
}

#endif
