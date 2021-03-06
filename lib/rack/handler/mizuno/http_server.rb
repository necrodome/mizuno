#
# A Rack handler for Jetty 7.
#
# Written by Don Werve <don@madwombat.com>
#

require 'java'
require 'rack'

# Load Jetty JARs.
jars = File.join(File.dirname(__FILE__), '..', '..', '..', 'java', '*.jar')
Dir[jars].each { |j| require j }

# Load the Rack/Servlet bridge.
require 'rack/handler/mizuno/rack_servlet'

# Have Jetty log to stdout for the time being.
java.lang.System.setProperty("org.eclipse.jetty.util.log.class", 
    "org.eclipse.jetty.util.log.StdErrLog")

module Rack::Handler::Mizuno
    class HttpServer
	include_class 'org.eclipse.jetty.server.Server'
	include_class 'org.eclipse.jetty.servlet.ServletContextHandler'
	include_class 'org.eclipse.jetty.servlet.ServletHolder'
	include_class 'org.eclipse.jetty.server.nio.SelectChannelConnector'
	include_class 'org.eclipse.jetty.util.thread.QueuedThreadPool'

	def self.run(app, options = {})
	    # The Jetty server
	    server = Server.new

	    # Thread pool
	    thread_pool = QueuedThreadPool.new
	    thread_pool.min_threads = 5
	    thread_pool.max_threads = 50
	    server.set_thread_pool(thread_pool)

	    # Connector
	    connector = SelectChannelConnector.new
	    connector.setPort(options[:Port].to_i)
	    connector.setHost(options[:Host])
	    server.addConnector(connector)

	    # Servlet context.
	    context = ServletContextHandler.new(nil, "/", 
		ServletContextHandler::NO_SESSIONS)

	    # The servlet itself.
	    servlet = RackServlet.new
	    servlet.rackup(app)
	    holder = ServletHolder.new(servlet)
	    context.addServlet(holder, "/")

	    # Add the context to the server and start.
	    server.set_handler(context)
	    puts "Started Jetty on #{connector.getHost}:#{connector.getPort}"
	    server.start
	end
    end
end

# Register ourselves with Rack when this file gets loaded.
Rack::Handler.register 'mizuno', 'Rack::Handler::Mizuno::HttpServer'
