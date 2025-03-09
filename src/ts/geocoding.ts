import axios from 'axios'
import dotenv from 'dotenv'
import { CSVStation } from './model/station'

interface AddressComponent {
  long_name: string,
  short_name: string,
  types: string[],
}

interface GeocodingResult {
  address_components: AddressComponent[],
  formatted_address: string,
}

interface GeocodingResponse {
  status: string,
  results: GeocodingResult[],
}

// 環境変数の読み込み
dotenv.config({ path: 'src/.env.local' })
const API_KEY = process.env.GOOGLE_GEOCODING_API_KEY

if (!API_KEY) {
  throw new Error('GOOGLE_GEOCODING_API_KEY is not set in environment variables')
}

export async function fetchAddress(station: Readonly<CSVStation>): Promise<Pick<CSVStation, 'postal_code' | 'address'>> {
  console.log(`駅の住所を取得中: ${station.name}`)

  try {
    const response = await axios.get<GeocodingResponse>('https://maps.googleapis.com/maps/api/geocode/json', {
      params: {
        latlng: `${station.lat},${station.lng}`,
        key: API_KEY,
        language: 'ja',
      },
    })

    if (response.data.status !== 'OK') {
      throw new Error(`Geocoding API error: ${JSON.stringify(response.data, null, 2)}`)
    }

    const result = response.data.results[0]
    console.log('response:', result)

    // 郵便番号の抽出
    const postalComponents = result.address_components.filter(
      c => c.types.includes('postal_code'),
    )

    if (postalComponents.length !== 1) {
      throw new Error('Failed to extract postal code')
    }

    const dst = {
      postal_code: postalComponents[0].long_name,
      address: '',
    }

    // 住所の構築
    const exception = ['postal_code', 'country', 'bus_station', 'train_station', 'transit_station']
    const addressComponents = result.address_components
      .filter(c => !c.types.some(t => exception.includes(t)))
      .map(c => c.long_name)

    let address = ''
    const numberPattern = /^[0-9０-９]+$/
    let previous: string | null = null

    addressComponents.reverse().forEach(component => {
      if (previous && numberPattern.test(previous) && numberPattern.test(component)) {
        address += '-'
      }
      address += component
      previous = component
    })

    dst.address = address
    console.log('result:', dst)
    return dst
  } catch (error) {
    if (axios.isAxiosError(error)) {
      throw new Error(`Failed to fetch geocoding data: ${error.message}`)
    }
    throw error
  }
} 