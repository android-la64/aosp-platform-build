/*
 * Copyright (C) 2024 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

//! flag table query module defines the flag table file read from mapped bytes

use crate::{AconfigStorageError, FILE_VERSION};
use aconfig_storage_file::{
    flag_table::FlagTableHeader, flag_table::FlagTableNode, read_u32_from_bytes, StoredFlagType,
};
use anyhow::anyhow;

/// Flag table query return
#[derive(PartialEq, Debug)]
pub struct FlagOffset {
    pub flag_type: StoredFlagType,
    pub flag_id: u16,
}

/// Query flag within package offset
pub fn find_flag_offset(
    buf: &[u8],
    package_id: u32,
    flag: &str,
) -> Result<Option<FlagOffset>, AconfigStorageError> {
    let interpreted_header = FlagTableHeader::from_bytes(buf)?;
    if interpreted_header.version > crate::FILE_VERSION {
        return Err(AconfigStorageError::HigherStorageFileVersion(anyhow!(
            "Cannot read storage file with a higher version of {} with lib version {}",
            interpreted_header.version,
            FILE_VERSION
        )));
    }

    let num_buckets = (interpreted_header.node_offset - interpreted_header.bucket_offset) / 4;
    let bucket_index = FlagTableNode::find_bucket_index(package_id, flag, num_buckets);

    let mut pos = (interpreted_header.bucket_offset + 4 * bucket_index) as usize;
    let mut flag_node_offset = read_u32_from_bytes(buf, &mut pos)? as usize;
    if flag_node_offset < interpreted_header.node_offset as usize
        || flag_node_offset >= interpreted_header.file_size as usize
    {
        return Ok(None);
    }

    loop {
        let interpreted_node = FlagTableNode::from_bytes(&buf[flag_node_offset..])?;
        if interpreted_node.package_id == package_id && interpreted_node.flag_name == flag {
            return Ok(Some(FlagOffset {
                flag_type: interpreted_node.flag_type,
                flag_id: interpreted_node.flag_id,
            }));
        }
        match interpreted_node.next_offset {
            Some(offset) => flag_node_offset = offset as usize,
            None => return Ok(None),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use aconfig_storage_file::test_utils::create_test_flag_table;

    #[test]
    // this test point locks down table query
    fn test_flag_query() {
        let flag_table = create_test_flag_table().into_bytes();
        let baseline = vec![
            (0, "enabled_ro", StoredFlagType::ReadOnlyBoolean, 1u16),
            (0, "enabled_rw", StoredFlagType::ReadWriteBoolean, 2u16),
            (1, "disabled_ro", StoredFlagType::ReadOnlyBoolean, 0u16),
            (2, "enabled_ro", StoredFlagType::ReadOnlyBoolean, 1u16),
            (1, "enabled_fixed_ro", StoredFlagType::FixedReadOnlyBoolean, 1u16),
            (1, "enabled_ro", StoredFlagType::ReadOnlyBoolean, 2u16),
            (2, "enabled_fixed_ro", StoredFlagType::FixedReadOnlyBoolean, 0u16),
            (0, "disabled_rw", StoredFlagType::ReadWriteBoolean, 0u16),
        ];
        for (package_id, flag_name, flag_type, flag_id) in baseline.into_iter() {
            let flag_offset =
                find_flag_offset(&flag_table[..], package_id, flag_name).unwrap().unwrap();
            assert_eq!(flag_offset.flag_type, flag_type);
            assert_eq!(flag_offset.flag_id, flag_id);
        }
    }

    #[test]
    // this test point locks down table query of a non exist flag
    fn test_not_existed_flag_query() {
        let flag_table = create_test_flag_table().into_bytes();
        let flag_offset = find_flag_offset(&flag_table[..], 1, "disabled_fixed_ro").unwrap();
        assert_eq!(flag_offset, None);
        let flag_offset = find_flag_offset(&flag_table[..], 2, "disabled_rw").unwrap();
        assert_eq!(flag_offset, None);
    }

    #[test]
    // this test point locks down query error when file has a higher version
    fn test_higher_version_storage_file() {
        let mut table = create_test_flag_table();
        table.header.version = crate::FILE_VERSION + 1;
        let flag_table = table.into_bytes();
        let error = find_flag_offset(&flag_table[..], 0, "enabled_ro").unwrap_err();
        assert_eq!(
            format!("{:?}", error),
            format!(
                "HigherStorageFileVersion(Cannot read storage file with a higher version of {} with lib version {})",
                crate::FILE_VERSION + 1,
                crate::FILE_VERSION
            )
        );
    }
}
