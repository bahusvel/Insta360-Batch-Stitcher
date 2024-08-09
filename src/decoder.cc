#include <string>
#include <iostream>
#include <fstream>
#include <cstring>
#include <stitcher/common.h>
#include <cstdint>

#define TRAILER_OFFSET -78
#define MAGIC_OFFSET -32

void hexdump(char * buf, size_t size) {
    for (int i; i < size; i++) printf("%02X ", buf[i] & 0xff);
    std::cout << "\n";
}

CameraAccessoryType parse_accessory(std::string file_path) {
    std::ifstream file(file_path);
    char *buf = new char[2048];

    if (!file.is_open()) {
        std::cout << "Unable to open " << file_path << "\n";
        return CameraAccessoryType::kNormal;
    }

    file.seekg(MAGIC_OFFSET, std::ios_base::end);
    file.read(buf, 32);
    if (strncmp(buf, "8db42d694ccc418790edff439fe026bf", 32) != 0) {
        std::cout << "Invalid Magic" << "\n";
        return CameraAccessoryType::kNormal;
    }

    int64_t offset = TRAILER_OFFSET;
    int32_t length;
    int count = 0;

    while (count++ < 10) { // Find 0x0101 record
        // std::cout << "Offset " << offset << "\n";
        file.seekg(offset, std::ios_base::end);
        file.read(buf, 6);
        
        int16_t type = *(uint16_t*)buf;
        length = *(uint32_t*)&buf[2];

        // printf("Section 0x%04x Length %d\n", type, length);

        if (type == 0x0101) break;
        offset -= length + 6;
    }

    if (length > 2048) { 
        std::cout << "0x101 section too long" << "\n";
        return CameraAccessoryType::kNormal;
    }

    file.seekg(offset-length, std::ios_base::end);
    file.read(buf, length);

    
    // Can't seem to figure out what happens after 4th record
    // It no longer follows the format documented here https://subethasoftware.com/2022/06/08/insta360-one-x2-insv-file-format/
    // It's supposed to be 1 byte type, 1 byte length, but it isn't after 4th record.
    // int count = 0;
    //int buf_offset = 0;
    // while (buf_offset < length) {
    //     uint8_t type = buf[buf_offset];
    //     uint8_t length = buf[buf_offset+1] & 0x7F;

    //     printf("Type 0x%02x Length %d\n", type, length);
    //     if (type == 0x38) {
            
    //         hexdump(&buf[buf_offset], 20);
    //         break;
    //     }
    //     buf_offset += length + 2;

    // }

    char type = -1;
    for (int o = 0; o < length; o++) {
        if (*(uint32_t*)&buf[o] == 0x04A00FD0) { // search for magic precursor
            // std::cout << "Magic precursor found" << "\n";
            type = buf[o+4];
            break;
        }
    }

    if (type == -1) {
        std::cout << "Magic precursor not found" << "\n";
        hexdump(buf, length);
    }

    switch ((int)type) {
        case 0: // Nothing
            return CameraAccessoryType::kNormal;
        case 3: // Dive Case
            return CameraAccessoryType::kOnex3DiveCaseWater;
        case 4: // Standard 
            return CameraAccessoryType::kOnex4ProtectShellA;
        case 5: // Premium
            return CameraAccessoryType::kOnex4ProtectShellS;
        default:
            std::cout << "Unrecognized accessory byte " << type << "\n";
    }
    
    return CameraAccessoryType::kNormal;
}

int main(int argc, char* argv[]) {
    CameraAccessoryType accessory_type = static_cast<CameraAccessoryType>(-1);
    std::cout << (int)parse_accessory(std::string(argv[1])) << "\n";
}