#include "runtime.hpp"
#ifdef NETWORK_RTL
#include "network_rtl.hpp"
int main(int argc,char**argv) { return net::run<net::Rtl>(argc,argv); }
#else
#include "network_model.hpp"
int main(int argc,char**argv) { return net::run<net::Model>(argc,argv); }
#endif
