import { NextResponse } from 'next/server';
import axios from 'axios';

export async function POST(request) {
  const { searchParams } = new URL(request.url);
  const url = searchParams.get('url');
  
  if (!url) {
    return NextResponse.json({ error: 'URL is required' }, { status: 400 });
  }

  // Use internal Kubernetes DNS if running in cluster (simple check)
  // Otherwise fallback to public hostname
  const backendBaseUrl = process.env.KUBERNETES_SERVICE_HOST
    ? 'http://qr-api-service'   // inside cluster
    : 'https://qr.duyngo.xyz';  // local/dev environment

  try {
    const response = await axios.post(`${backendBaseUrl}/api/generate-qr?url=${encodeURIComponent(url)}`);
    return NextResponse.json(response.data);
  } catch (error) {
    console.error('Error generating QR Code:', error);
    return NextResponse.json({ error: 'Failed to generate QR Code' }, { status: 500 });
  }
}
