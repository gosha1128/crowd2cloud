/**
 * Class for connecting to the Vicon server or running a simulation.
 *
 * Note that ViconData is responsible for determining the drawing volume. For now this is
 * hard-coded, but it could change in the future.
 *
 */

class ViconData {

  boolean simulated;
  int f, numberLines;
  String[] lines;

  PVector minXYZ, maxXYZ, meanXYZ, deltaXYZ;

  // VICON PROXY STUFF->
  int PROXY_PORT = 6667;
  int DEFAULT_BUF_SIZE = 65507;
  DatagramSocket  ucSocket = null;
  // <-VICON PROXY STUFF

  ViconData(boolean simulated) { 

    this.simulated = simulated;

    minXYZ = new PVector(-4000, -6000, 0);
    maxXYZ = new PVector(4800, 1200, 3300);

    deltaXYZ = PVector.sub(maxXYZ, minXYZ);
    meanXYZ = PVector.add(maxXYZ, minXYZ);
    meanXYZ.div(2);    

    if (simulated) {
      lines = loadStrings("recording.txt");
      numberLines = lines.length;
    } 
    else {
      vicon_proxy_init();
    }
  }

  void skipFrames(int num) {
    f+= num;
    f = f % numberLines;
  }

  String getData() {

    if (simulated) {
      String l = lines[f];
      f++;
      if (f >= numberLines) f = 0;
      String data = l.substring( 0, l.length());
      return data;
    } 
    else {
      return vicon_proxy_get_data();
    }
  }




  // VICON PROXY STUFF->
  //
  //  Initialize connection to ViconProxy...
  //
  void vicon_proxy_init() {    
    println(PROXY_PORT);
    try {
      ucSocket = new DatagramSocket( PROXY_PORT, null );
      ucSocket.setReceiveBufferSize( DEFAULT_BUF_SIZE );
    } 
    catch( IOException e ) {
      System.out.println("ERROR1: " + e.getMessage()); // TODO: should probably quit Processing here...
    }
  }


  //
  //  Get latest ViconProxy data packet...
  //
  String vicon_proxy_get_data() {
    try {

      byte[] buffer           = new byte[ 65507 ];
      DatagramPacket pa       = new DatagramPacket(buffer,buffer.length);
      DatagramPacket last_good_pa     = new DatagramPacket(buffer,buffer.length);
      int pkts_in_queue = 0;

      //      Keep reading packets until end of buffer...
      while (true) {
        try {
          ucSocket.setSoTimeout( 1 ); // at worst, its a 1 ms delay...
          ucSocket.receive( pa );
          last_good_pa = pa;
          pkts_in_queue++;
        }
        catch ( Exception e ) {
          if ( e instanceof SocketTimeoutException )  { // means no more packets
            pa = last_good_pa; // return the last packet read...
            break;
          } else {
            System.out.println("ERROR2: " + e.toString());
            return "";
            //throw e; // some other exception - better let the previous code handle it by rethrowing the exc...
          }
        }
      }
      
      if ( pa.getLength()!=0 ) {
        byte[] data = new byte[ pa.getLength() ];
        System.arraycopy( pa.getData(), 0, data, 0, data.length );

        data = subset(data, 0, data.length);
        String message = new String( data );
        return message;
      }
    }
    catch( Exception e ) {
      System.out.println("ERROR3: " + e.getMessage() );
      return "";
    }
    return "";
  }
}

